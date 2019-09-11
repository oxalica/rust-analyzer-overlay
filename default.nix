self: super:

let
  rev = "6ce6744e18f25ebcde387178125d820686692df5";
  sha256 = "1c89k24hvjrsb3gm8bgw0k2vxsn19n4dix7dnv7fk34qy06h8cwk";
  cargoSha256 = "086fcidsm3psnz9hcpbgrx30hbx2f7d5wz4v9b2smzrajpwmddar";

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

