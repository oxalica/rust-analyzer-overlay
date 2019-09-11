{ lib, rustPlatform, makeWrapper, runCommand
, src, version, cargoSha256
}:

lib.makeOverridable ({ src, rustcSrc, useJemalloc, doCheck, buildType, rustcSrcCheck ? rustcSrc }: let
  unwrapped = rustPlatform.buildRustPackage {
    pname = "rust-analyzer-unwrapped";

    inherit src version cargoSha256 doCheck buildType;

    nativeBuildInputs = if doCheck
      then assert rustcSrcCheck != null; [ rustcSrcCheck ]
      else [];

    cargoBuildFlags = lib.optional useJemalloc "--features jemalloc";

    preCheck = lib.optionalString doCheck ''
      export RUST_SRC_PATH="${rustcSrcCheck}"
    '';
  };

in runCommand "rust-analyzer-${unwrapped.version}" {
  inherit (unwrapped) version src;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ unwrapped rustcSrc ];
} ''
  for name in ra_cli ra_lsp_server ra_tools website-gen; do
    makeWrapper "${unwrapped}/bin/$name" "$out/bin/$name" ${lib.optionalString (rustcSrc != null) ''
      --set-default RUST_SRC_PATH "${rustcSrc}"
    ''}
  done
'') {
  inherit src;
  rustcSrc = rustPlatform.rustcSrc;
  useJemalloc = false;
  doCheck = false;
  buildType = "release";
}
