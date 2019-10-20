{ lib, rustPlatform, makeWrapper, runCommand
, src, version, cargoSha256
, rustcSrc ? rustPlatform.rustcSrc
, rustcSrcCheck ? rustcSrc
, buildType ? "release"
, doCheck ? false
, useJemalloc ? false
}:

let
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
  buildInputs = [ unwrapped ] ++ lib.optional (rustcSrc != null) rustcSrc;
} ''
  for name in ra_cli ra_lsp_server xtask; do
    makeWrapper "${unwrapped}/bin/$name" "$out/bin/$name" ${lib.optionalString (rustcSrc != null) ''
      --set-default RUST_SRC_PATH "${rustcSrc}"
    ''}
  done
''

