self: super:

let
  rev = "5a99184967c89992df4544d0c1ca27d79946a1a7";
  sha256 = "1pn2zbsjjw9lrrk1am534xs502w6imrqz8z8p1h25446wl0v21ii";
  cargoSha256 = "0dj4xgqxsz3jnm9lwlm50qwq1zxjp75ggxgqv6g036szlhs3f8hw";

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
      src = "${src}/editors/code";
    };
  };
}

