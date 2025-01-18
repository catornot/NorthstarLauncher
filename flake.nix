{
  description = "NorthstarLauncher";

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
        pkgs = import nixpkgs { inherit system; };
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        packages = rec {
          northstar = pkgs.callPackage ./default.nix { pkgs = pkgs; };
          default = northstar;
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            docker
          ];

          buildInputs = [
          ];
        };
      }
    );
}
