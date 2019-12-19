self: super:

let
  rev = "08c6933104baca84fd4135a76cdc7daf60a0c631";
  sha256 = "0wjlp115jgmc2s01aggdk77i96xkwggfbg1rsl92d7l952j0fga9";
  cargoSha256 = "0cghcmkhqwfxs1xcj7m0vv4wwqmff6s12jdh1bhar27x45v52slh";

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

