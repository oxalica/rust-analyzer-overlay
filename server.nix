{ lib, rustPlatform, makeWrapper, runCommand
, src, version, cargoSha256
}:

lib.makeOverridable ({ rustcSrc, useJemalloc, doCheck, buildType }: let

  unwrapped = rustPlatform.buildRustPackage {
    pname = "rust-analyzer-unwrapped";

    inherit src version cargoSha256 doCheck buildType;

    patches = [ ./rustc-src-path.patch ];

    nativeBuildInputs = if doCheck then [ rustcSrc ] else [];

    cargoBuildFlags = lib.optional useJemalloc "--features jemalloc";

    preCheck = ''
      export RUSTC_SRC_PATH="${rustcSrc}"
    '';
  };

in runCommand "rust-analyzer-${unwrapped.version}" {
  inherit (unwrapped) version;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ unwrapped rustcSrc ];
} ''
  for file in ${unwrapped}/bin/*; do
    makeWrapper "$file" "$out/bin/$(basename "$file")" \
      --set RUSTC_SRC_PATH "${rustcSrc}"
  done
'') {
  rustcSrc = rustPlatform.rustcSrc;
  useJemalloc = false;
  doCheck = false;
  buildType = "release";
}

