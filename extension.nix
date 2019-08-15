{ lib, vscode, vscode-utils, breakpointHook
, version, src, extName, extPublisher, extVersion
}:

let 
  vsixPackage = (import ./extension-lock {}).package.override {
    name = "vscode-extension-${extName}-src-${version}";
    inherit src version;

    outputs = [ "out" "vsix" ];

    nativeBuildInputs = [ vscode breakpointHook ];

    npmFlags = "--ignore-scripts";

    postInstall = ''
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

