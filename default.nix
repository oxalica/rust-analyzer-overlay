self: super:

let
  rev = "8a4c248c48ad7bb9ad556717ee013129c190dbfa";
  sha256 = "0g0sqg215ab55qp9p9n0bsqc3f01gjapg41hmc724siwc61vvgaq";
  cargoSha256 = "0hdj1nnj5phjnmiq87bz2i8wbq70c2g8kkqjb8yssnrmx15780g7";

  extName = "rust-analyzer";
  extVersion = "0.1.0";
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

