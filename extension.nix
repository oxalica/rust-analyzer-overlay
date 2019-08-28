{ lib, vscode, vscode-utils, jq, rust-analyzer
, version, src, extName, extPublisher, extVersion
}:

let 
  vsixPackage = (import ./extension-lock {}).package.override {
    name = "vscode-extension-${extName}-src-${version}";
    inherit src version;

    outputs = [ "out" "vsix" ];

    nativeBuildInputs = [ vscode jq ];
    buildInputs = [ rust-analyzer ];

    npmFlags = "--ignore-scripts";

    postInstall = ''
      jq '.contributes.configuration.properties."rust-analyzer.raLspServerPath".default = $s' \
        --arg s "${rust-analyzer}/bin/ra_lsp_server" \
        package.json >package.json.tmp
      mv -f package.json.tmp package.json

      cp "${vscode}/lib/vscode/resources/app/out/vs/vscode.d.ts" ./node_modules/vscode
      npm run package
      mkdir -p $vsix/share
      mv ${extName}-${extVersion}.vsix $vsix/share/${extName}.vsix.zip
    '';
  };

in vscode-utils.buildVscodeExtension {
  name = "${extPublisher}-${extName}-${version}";
  inherit version;
  src = "${vsixPackage.vsix}/share/${extName}.vsix.zip";
  vscodeExtUniqueId = "${extPublisher}.${extName}";
}

