{ lib, rustPlatform, makeWrapper, runCommand
, src, version, cargoSha256
}:

lib.makeOverridable ({ rustcSrc, useJemalloc, doCheck, buildType }: let

  unwrapped = rustPlatform.buildRustPackage {
    pname = "rust-analyzer-unwrapped";

    inherit src version cargoSha256 doCheck buildType;

    nativeBuildInputs = if doCheck then [ rustcSrc ] else [];

    cargoBuildFlags = lib.optional useJemalloc "--features jemalloc";

    preCheck = ''
      export RUST_SRC_PATH="${rustcSrc}"
    '';
  };

in runCommand "rust-analyzer-${unwrapped.version}" {
  inherit (unwrapped) version src;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ unwrapped rustcSrc ];
} ''
  for name in ra_cli ra_lsp_server ra_tools website-gen; do
    makeWrapper "${unwrapped}/bin/$name" "$out/bin/$name" \
      --set-default RUST_SRC_PATH "${rustcSrc}"
  done
'') {
  rustcSrc = rustPlatform.rustcSrc;
  useJemalloc = false;
  doCheck = false;
  buildType = "release";
}

