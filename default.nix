self: super:

let
  rev = "793f7e69f298ccb14936a33c59d7df1527b39af6";
  sha256 = "1zrykmaxlvp5szpnfpp692h9a6h37ssr48m788sy9s5zjcjvs8pl";
  cargoSha256 = "0mxp94i55k8379xbkjchyas38ms29yyd1bk09dg53yb1jb079mlc";

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

