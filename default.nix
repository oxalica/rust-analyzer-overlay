self: super:

let
  rev = "2c7f6b573e9b6133cc147a529dd2a23119bb4ae5";
  sha256 = "0lvnm07rnf8i5a590nrk3abc8l211pqapzc0fkygwhsx4aiifn58";
  cargoSha256 = "12nxq54isglx3fa61nllf9pwj3pdjdz8mg2lbm3z7hff738l0h1r";

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

