{ lib, vscode-utils, jq, unzip
, version, src, extName, extPublisher, extVersion
, rust-analyzer # Set to null to use default global rust-analyzer
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
      ${lib.optionalString (rust-analyzer != null) ''
        jq '.contributes.configuration.properties."rust-analyzer.raLspServerPath".default = $s' \
          --arg s "${rust-analyzer}/bin/ra_lsp_server" \
          package.json >package.json.tmp
        mv -f package.json.tmp package.json
      ''}

      patch -p1 <${./no-version-check.patch}

      mkdir -p $vsix/share/vscode/extensions
      $(npm bin)/vsce package -o $vsix/share/vscode/extensions/${extPublisher}.${extName}.vsix
    '';
  };

in vscode-utils.buildVscodeExtension {
  name = "${extPublisher}-${extName}-${version}";
  inherit version;

  nativeBuildInputs = [ unzip ];

  src = "${vsixPackage.vsix}/share/vscode/extensions/${extPublisher}.${extName}.vsix";

  unpackPhase = ''
    unzip $src
  '';

  vscodeExtUniqueId = "${extPublisher}.${extName}";

  inherit (vsixPackage) vsix;
}
