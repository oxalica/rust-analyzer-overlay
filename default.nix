self: super:

let
  rev = "ec164fbb68a4252ef56497ba95501c0f4417ef4e";
  sha256 = "1apaa54yxahxzzqripv80rgl8hlvzngj515f770z60ij49vh76ck";
  cargoSha256 = "0xdsvmwvlvilq0vbqlrixplmqvpnja3sb75m9bvnakawkymm4bj0";

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

