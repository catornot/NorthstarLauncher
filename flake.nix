{
  description = "a collection of plugins for northstar related to bots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        sys-pkgs = import nixpkgs { inherit system; };
        pkgs = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "x86_64-w64-mingw32";
            libc = "msvcrt";
          };
        };
      in
      {
        nixpkgs.config.allowUnsupportedSystem = true; # hmmm doesn work?
        formatter = sys-pkgs.nixfmt-rfc-style;
        packages = rec {
          northstar = pkgs.callPackage ./default.nix { pkgs = pkgs; };
          default = northstar;
        };

        devShell = pkgs.mkShell rec {
          nativeBuildInputs = with pkgs; [
            pkgsCross.mingwW64.buildPackages.cmake
            pkgsCross.mingwW64.buildPackages.pkg-config
            pkgsCross.mingwW64.buildPackages.ninja
            pkgsCross.mingwW64.buildPackages.lld
            pkgsCross.mingwW64.buildPackages.bintools
          ];

          buildInputs = with pkgs; [
            windows.mingw_w64_headers
            windows.mcfgthreads
            windows.mingw_w64_pthreads
          ];
          LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath buildInputs;
          PATH = nixpkgs.lib.makeLibraryPath buildInputs;
          WINEPATH = nixpkgs.lib.makeLibraryPath buildInputs;
        };
      }
    );
}
