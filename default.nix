self: super:

let
  rev = "419eec3d2f3db71ce317d08342b59abd764dd324";
  sha256 = "1kgbk4ryz86d6yg2lf5irf61dgvxs2z4xi73njda3ir3p70s8af8";
  cargoSha256 = "1dkwwxr2flmdlcsd2fmkr4z1vk1jikbgwp0bflnwrxpmbj4gkpr9";

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

