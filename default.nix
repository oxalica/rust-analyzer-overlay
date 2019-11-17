self: super:

let
  rev = "d0357fc3b270d5b05665395b95958ac2a3d1c51a";
  sha256 = "1zi81qpicr6c0k4y22waw1fqcl524w131rf6fpa2w4l733v160i3";
  cargoSha256 = "1bzgs6v6bly2ackfq2li98w0cb61r3858hrfvd6icd98h6bapvf2";

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

