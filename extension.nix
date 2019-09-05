{ lib, vscode-utils, jq, rust-analyzer
, version, src, extName, extPublisher, extVersion
}:

let 
  vsixPackage = (import ./extension-lock {}).package.override {
    name = "vscode-extension-${extName}-src-${version}";
    inherit src version;

    outputs = [ "out" "vsix" ];

    nativeBuildInputs = [ jq ];
    buildInputs = [ rust-analyzer ];

    npmFlags = "--ignore-scripts";

    # `node2nix` generated file locks dependencies, which will fail version checking.
    postInstall = ''
      jq '.contributes.configuration.properties."rust-analyzer.raLspServerPath".default = $s' \
        --arg s "${rust-analyzer}/bin/ra_lsp_server" \
        package.json >package.json.tmp
      mv -f package.json.tmp package.json

      patch -p1 <${./no-version-check.patch}

      mkdir -p $vsix/share
      $(npm bin)/vsce package -o $vsix/share/${extName}.vsix.zip
    '';
  };

in vscode-utils.buildVscodeExtension {
  name = "${extPublisher}-${extName}-${version}";
  inherit version;
  src = "${vsixPackage.vsix}/share/${extName}.vsix.zip";
  vscodeExtUniqueId = "${extPublisher}.${extName}";
}

