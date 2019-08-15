self: super:

let
  rev = "b1b6a90ab168c3d04038a28a3c02c69a507a3f52";
  sha256 = "1f1148cj755v0xc3x41nlbhsz4j8f6h4rvzbw718ziw8rr6q1qxk";
  cargoSha256 = "19hpysddb98isi2k94qzvl8sa0lhgmgajvdxw9lhk7973h5n8ydc";

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
      src = "${src}/editors/code";
    };
  };
}

