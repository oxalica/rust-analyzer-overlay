self: super:

let
  rev = "b8c16ec002d48f4fb9d883d091114ccd1286ba47";
  sha256 = "0f5ds8s0y9pa5jj2igiw553cx7ivcbawgc1nqqa572f8d1fdlq0n";
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

