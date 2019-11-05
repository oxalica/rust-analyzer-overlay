self: super:

let
  rev = "38f2bd21fbecf1c997a4ab9a8913e8b5487088e3";
  sha256 = "1qf123lbpzg6g3zh1v6ir24ybi26g6zrhz5w1iqwf1420dkgwkip";
  cargoSha256 = "0psq134j8frbp2axhlkq37gx5ri75d0633mp774agpm1zdzszap3";

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

