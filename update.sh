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


function build_server() {
  nix-build --no-out-link \
    --argstr overlay "$(realpath "$nix_file")" \
    -E '{ overlay }: with import <nixpkgs> {};
      (import overlay pkgs pkgs).rust-analyzer'
}

function build_extension() {
  local ext_publisher ext_name
  IFS=";" read ext_publisher ext_name <<<"$1"

  # `vscode` is unfree
  NIXPKGS_ALLOW_UNFREE=1 nix-build --no-out-link \
    --argstr overlay "$(realpath "$nix_file")" \
    --argstr publisher "$ext_publisher" \
    --argstr name "$ext_name" \
    -E '{ overlay, name, publisher }: with import <nixpkgs> {};
      (import overlay pkgs pkgs).vscode-extensions.${publisher}.${name}'
}

function fetch_master() {
  local rev=$(
    curl "https://api.github.com/repos/$repo_owner/$repo_name/branches/master" |
    jq '.commit.sha' --raw-output
  )
  [[ -n "$rev" ]]

  echo "$rev"
}

function prefetch_hash() {
  local rev="$1"

  local sha256=$(
    nix-prefetch-github --prefetch "$repo_owner" "$repo_name" --rev "$rev" |
    jq '.sha256' --raw-output
  )
  [[ "$sha256" ]]

  echo "$sha256"
}

function get_store_path() {
  local sha256="$1"

  local store_path=$(nix eval --raw "(
    with import <nixpkgs> {}; (fetchFromGitHub {
      owner = \"\";
      repo = \"\";
      rev = \"\";
      sha256 = \"$sha256\";
    }).outPath
  )")
  [[ "$store_path" ]]

  echo "$store_path"
}

function gen_extension_lock() {
  local sha256="$1"

  local store_path
  read store_path < <(get_store_path "$sha256")
  local ext_dir="$store_path/editors/code"
  echo "Store path: $store_path" >&2

  { read ext_publisher; read ext_name; read ext_version; } < <(
    cat "$ext_dir/package.json" |
    jq --raw-output '.publisher, .name, .version'
  )
  echo "Extension publisher: $ext_publisher, name: $ext_name, version: $ext_version" >&2
  [[ $ext_publisher && $ext_name && $ext_version &&
     $ext_publisher != "null" && $ext_name != "null" && $ext_version != "null" ]]

  echo "Generating extension lock nix" >&2
  pushd $ext_lock_dir
  node2nix --development --nodejs-10 \
    --input "$ext_dir/package.json" \
    --lock "$ext_dir/package-lock.json"
  popd
  echo "Generated" >&2

  echo "$ext_publisher;$ext_name;$ext_version"
}

function get_old_meta() {
  local rev=$(sed -n 's/.*\brev = "\(.*\)".*/\1/p' "$nix_file")
  local sha256=$(sed -n 's/.*\bsha256 = "\(.*\)".*/\1/p' "$nix_file")
  local cargo_sha=$(sed -n 's/.*\bcargoSha256 = "\(.*\)".*/\1/p' "$nix_file")
  local ext_publisher=$(sed -n 's/.*\bextPublisher = "\(.*\)".*/\1/p' "$nix_file")
  local ext_name=$(sed -n 's/.*\bextName = "\(.*\)".*/\1/p' "$nix_file")
  local ext_version=$(sed -n 's/.*\bextVersion = "\(.*\)".*/\1/p' "$nix_file")

  if ! [[ $rev && $sha256 && $cargo_sha && $ext_publisher && $ext_name && $ext_version ]]; then
    echo "Metadata not found in nix" >&2
    exit 1
  fi

  echo "$rev;$sha256;$cargo_sha;$ext_publisher;$ext_name;$ext_version"
}

function main() {
  local mode="$1"

  local rev sha256 cargo_sha ext_publisher ext_name ext_version
  IFS=";" read rev sha256 cargo_sha ext_publisher ext_name ext_version < <(get_old_meta)

  if [[ $mode = "build" ]]; then
    echo "Building..." >&2
    build_server
    build_extension "$ext_publisher;$ext_name"
    return
  elif [[ $mode = "gen-lock" ]]; then
    gen_extension_lock "$sha256" >/dev/null
    return
  fi

  echo "Fetching master..." >&2
  local new_rev=$(fetch_master)
  echo "rev: $new_rev" >&2

  local cargo_sha_placeholder="0000000000000000000000000000000000000000000000000000"

  if [[ "$rev" == "$new_rev" ]]; then
    echo "Already the latest" >&2
  else

    echo "Prefetching..." >&2
    read sha256 < <(prefetch_hash "$rev")
    echo "sha256: $sha256" >&2

    IFS=";" read ext_publisher ext_name ext_version <(gen_extension_lock "$sha256")

    sed --in-place \
      -e "s/rev = \".*\"/rev = \"$rev\"/" \
      -e "s/sha256 = \".*\"/sha256 = \"$sha256\"/" \
      -e "s/cargoSha256 = \".*\"/cargoSha256 = \"$cargo_sha_placeholder\"/" \
      -e "s/extPublisher = \".*\"/extPublisher = \"$ext_publisher\"/" \
      -e "s/extName = \".*\"/extName = \"$ext_name\"/" \
      -e "s/extVersion = \".*\"/extVersion = \"$ext_version\"/" \
      "$nix_file"
    echo "Updated hashes and placeholder" >&2

    cargo_sha=$cargo_sha_placeholder
  fi

  if [[ "$cargo_sha" != "$cargo_sha_placeholder" ]]; then
    echo "cargoSha256 is already filled" >&2
  else

    echo "Prebuilding nix..." >&2
    cargo_sha=$(
      build_server 2>&1 |
      tee /dev/stderr |
      sed -n 's/^\s*got:\s*sha256:\(.*\)/\1/p'
    )
    if [[ -z "$cargo_sha" ]]; then
      echo "Cannot found cargoSha256" >&2
      exit 1
    fi

    sed --in-place \
      -e "s/cargoSha256 = \".*\"/cargoSha256 = \"$cargo_sha\"/" \
      "$nix_file"
    echo "Updated cargoSha256" >&2
  fi

  echo "Done bumpping" >&2
}

if [[ -z "$1" ]]; then
  main bump
  main build
elif [[ "$1" = "bump" || "$1" = "build" || "$1" = "gen-lock" ]]; then
  main "$1"
else
  echo "Usage: $0 [bump | build | gen-lock]" >&2
  exit 1
fi

