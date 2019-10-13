self: super:

let
  rev = "264a07975d23ad4d7cb41b309ba4a4c0a507a028";
  sha256 = "13clgfgz494gvb4rk022lk1rlk9pn48ig1a3nf67534hxpqcgv9p";
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

