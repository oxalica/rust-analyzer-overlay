self: super:

let
  rev = "0cce2bc0ab03a291f0692f5298f04519a6ff8abe";
  sha256 = "06dgx3l3ikwk4mybqwlxrinrh9m6cgm67fgvz1dx2x3m1b84q496";
  cargoSha256 = "1jzgklwxxq8ks56416h443h0xins099k889r18iryzygv5pi2z6s";

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

