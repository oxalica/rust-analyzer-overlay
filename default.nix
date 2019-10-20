self: super:

let
  rev = "6b9bd7bdd2712a7e85d6bfc70c231dbe36c2e585";
  sha256 = "0wn2la5894lx11a0wa433aygvd1slll5fri0hq54yvsl5agrm4vf";
  cargoSha256 = "0mwlrhf19d84i7ssw60dw0vqm5wf57znj6xwxv1j9f03wvnlgj6s";

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

