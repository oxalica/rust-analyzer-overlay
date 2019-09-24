self: super:

let
  rev = "4c293c0a57fbe91587f6517403c30bb61ac21dc5";
  sha256 = "1vjl557zf6hjgmv294c1azncr34hfb5bxrvzlw41qwc17hq8lfkm";
  cargoSha256 = "0q8nv6gprdqzfq14l16p6aafw22l1nwqgyahrwmq33djw7sr4l3x";

  extName = "ra-lsp";
  extVersion = "0.0.1";
  extPublisher = "matklad";

  version = "git-${rev}";

  src = self.fetchFromGitHub {
    owner = "rust-analyzer";
    repo = "rust-analyzer";
    inherit rev sha256;
  };

in {
  rust-analyzer = self.callPackage ./server.nix {
    inherit version src cargoSha256;
  };

  vscode-extensions = self.lib.recursiveUpdate super.vscode-extensions {
    "${extPublisher}".${extName} = self.callPackage ./extension.nix {
      inherit version extName extVersion extPublisher;
      inherit (self.pkgs) rust-analyzer;
      src = "${self.pkgs.rust-analyzer.src}/editors/code";
    };
  };
}

