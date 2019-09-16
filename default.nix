self: super:

let
  rev = "6b33b90091b0cecd4c092d34451aba9f2492063c";
  sha256 = "1q5wz6vxm0l7ld72vqvp1k7swxq0020rv5p32297c4vv7qy580sx";
  cargoSha256 = "093w2jmg9rdsdv246p4cs09am1igdnabv1x6l1nyjgfapjx3dbsj";

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

