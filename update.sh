#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-github nodePackages.node2nix
set -e
which curl jq sed tee nix-prefetch-github nix-build node2nix >/dev/null

nix_file=$(dirname "$0")/default.nix
if [[ ! -e "$nix_file" ]]; then
  echo "Invalid nix file path: $nix_file" >&2
  exit 1
fi
ext_lock_dir=$(dirname "$nix_file")/extension-lock
if [[ ! -d "$ext_lock_dir" ]]; then
  echo "Invalid extension lock dir: $ext_lock_dir" >&2
  exit 1
fi

repo_owner="rust-analyzer"
repo_name="rust-analyzer"

cargo_sha_placeholder="0000000000000000000000000000000000000000000000000000"

function build_server() {
  nix-build --no-out-link \
    --argstr overlay "$(realpath "$nix_file")" \
    -E '{ overlay }: with import <nixpkgs> { overlays = [ (import overlay) ]; };
        rust-analyzer' \
    "$@"
}

function build_extension() {
  nix-build --no-out-link \
    --argstr overlay "$(realpath "$nix_file")" \
    --argstr publisher "$ext_publisher" \
    --argstr name "$ext_name" \
    -E '{ overlay, name, publisher }: with import <nixpkgs> { overlays = [ (import overlay) ]; };
        vscode-extensions.${publisher}.${name}' \
    "$@"
}

function get_info() {
  rev=$(sed -n 's/.*\brev = "\(.*\)".*/\1/p' "$nix_file")
  sha256=$(sed -n 's/.*\bsha256 = "\(.*\)".*/\1/p' "$nix_file")
  cargo_sha=$(sed -n 's/.*\bcargoSha256 = "\(.*\)".*/\1/p' "$nix_file")
  ext_publisher=$(sed -n 's/.*\bextPublisher = "\(.*\)".*/\1/p' "$nix_file")
  ext_name=$(sed -n 's/.*\bextName = "\(.*\)".*/\1/p' "$nix_file")
  ext_version=$(sed -n 's/.*\bextVersion = "\(.*\)".*/\1/p' "$nix_file")

  if ! [[ $rev && $sha256 && $cargo_sha && $ext_publisher && $ext_name && $ext_version ]]; then
    echo "Metadata not found in nix" >&2
    return 1
  fi
}

function bump() {
  get_info

  local new_rev
  if [[ $1 && ${1:0:1} != '-' ]]; then
    new_rev=$1
  fi
  
  if [[ -z $new_rev ]]; then
    echo "Fetching master..." >&2
    new_rev=$(
      curl "https://api.github.com/repos/$repo_owner/$repo_name/branches/master" |
      jq '.commit.sha' --raw-output
    )
    [[ $new_rev ]]
  fi
  echo "rev: $new_rev" >&2

  if [[ "$rev" == "$new_rev" ]]; then
    echo "Already the latest" >&2
    return
  fi

  rev=$new_rev

  echo "Prefetching..." >&2
  sha256=$(
    nix-prefetch-github --prefetch "$repo_owner" "$repo_name" --rev "$rev" |
    jq '.sha256' --raw-output
  )
  [[ $sha256 ]]
  echo "sha256: $sha256" >&2

  sed --in-place "$nix_file" \
    -e "s/rev = \".*\"/rev = \"$rev\"/" \
    -e "s/sha256 = \".*\"/sha256 = \"$sha256\"/" \
    -e "s/cargoSha256 = \".*\"/cargoSha256 = \"$cargo_sha_placeholder\"/"

  echo "Updated hashes and placeholder" >&2
}

function gen_lock() {
  get_info

  local store_path=$(nix eval --raw "(
    with import <nixpkgs> {}; (fetchFromGitHub {
      owner = \"\";
      repo = \"\";
      rev = \"\";
      sha256 = \"$sha256\";
    }).outPath
  )")
  echo "Store path: $store_path" >&2
  [[ "$store_path" ]]

  local ext_dir="$store_path/editors/code"

  { read ext_publisher; read ext_name; read ext_version; } < <(
    cat "$ext_dir/package.json" |
    jq --raw-output '.publisher, .name, .version'
  )
  echo "Extension publisher: $ext_publisher, name: $ext_name, version: $ext_version" >&2
  [[ $ext_publisher && $ext_name && $ext_version &&
     $ext_publisher != "null" && $ext_name != "null" && $ext_version != "null" ]]

  echo "Generating extension lock nix" >&2
  {
    pushd $ext_lock_dir
    node2nix --development --nodejs-10 \
      --input "$ext_dir/package.json" \
      --lock "$ext_dir/package-lock.json"
    sed --in-place \
      -e 's_^.*src = [./]*/nix/store.*__g' \
      ./node-packages.nix
    popd
  } >/dev/null
  echo "Generated" >&2

  sed --in-place "$nix_file" \
    -e "s/extPublisher = \".*\"/extPublisher = \"$ext_publisher\"/" \
    -e "s/extName = \".*\"/extName = \"$ext_name\"/" \
    -e "s/extVersion = \".*\"/extVersion = \"$ext_version\"/"
  
  echo "Updated extension meta" >&2
}

function pre_build_fill() {  
  get_info

  if [[ $cargo_sha != $cargo_sha_placeholder ]]; then
    echo "cargoSha256 is already filled" >&2
    return
  fi

  echo "Prebuilding nix..." >&2
  local cargo_sha=$(
    build_server "$@" 2>&1 |
    tee /dev/stderr |
    sed -n 's/^\s*got:\s*sha256:\(.*\)/\1/p'
  )
  if [[ -z "$cargo_sha" ]]; then
    echo "Cannot found cargoSha256" >&2
    return 1
  fi

  sed --in-place "$nix_file" \
    -e "s/cargoSha256 = \".*\"/cargoSha256 = \"$cargo_sha\"/"
  echo "Updated cargoSha256" >&2
}

function build() {
  get_info

  echo "Building..." >&2
  build_server "$@"
  build_extension "$@"
}

function pipeline() {
  bump "$1"
  shift
  gen_lock
  pre_build_fill "$@"
  build "$@"
}

case $1 in
  bump)
    bump $2
    ;;

  gen_lock)
    gen_lock
    ;;

  pre_build_fill)
    shift
    pre_build_fill "$@"
    ;;

  build)
    shift
    pre_build_fill "$@"
    ;;

  ""|-*)
    pipeline "" "$@"
    ;;

  ????????????????????????????????????????)
    pipeline "$@"
    ;;

  *)
    cat >&2 <<EOF
Usage: $0 [commit_id] [build_flags...]
       $0 bump [commit_id]
       $0 gen-lock
       $0 pre_build_fill [build_flags...]
       $0 build [build_flags...]
EOF
    exit 1
    ;;
esac

