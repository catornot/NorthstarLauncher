{
  description = "Northstar launcher";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnsupportedSystem = true;
        };
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
            microsoftVisualStudioLicenseAccepted = true;
            allowUnsupportedSystem = true;
          };
        };

        mkCross = pkgs: pkgs.pkgsCross.mingw-msvcrt-x86_64;
        cross = mkCross pkgs-unstable;
        cross-unstable = mkCross pkgs-unstable;

        toolchainFile = pkgs.writeText "WindowsToolchain.cmake" ''
          set(CMAKE_SYSTEM_NAME Windows)
          set(CMAKE_SYSTEM_VERSION 10.0)
        '';
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        packages = rec {
          northstar =
            with cross;
            cross.stdenv.mkDerivation rec {
              pname = "NorthstarLauncher";
              version = "1.31.6";
              # src = fetchFromGitHub {
              #   owner = "R2Northstar";
              #   repo = "NorthstarLauncher";
              #   rev = "v${version}";
              #   hash = "sha256-RQfMu5Gcsqemy35ZCCo6ABRy4ci4D5PaVzC1M+UMkNQ=";
              #   fetchSubmodules = true;
              # };
              src = ./.;

              nativeBuildInputs = [
                buildPackages.cmake
                buildPackages.ninja
                buildPackages.pkg-config
                buildPackages.perl
              ];

              buildInputs = [
                cross.windows.mingw_w64_headers
                cross.windows.pthreads
                cross.zlib
                cross.openssl
              ];

              cmakeFlags = [
                "-DCMAKE_SYSTEM_NAME=Windows"
                "-DCMAKE_SYSTEM_VERSION=10.0"

                "-DCMAKE_BUILD_TYPE=Release"
                "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

                # libcurl stuff
                "-DCURL_USE_WINDOWS_SOCKETS=ON"
                "-DUSE_WINSOCK=ON"
                "-DCMAKE_REQUIRED_LIBRARIES=ws2_32"
              ];

              meta = {
                description = "Northstar launcher";
                homepage = "https://northstar.tf/";
                license = pkgs.lib.licenses.mit;
                mainProgram = "NorthstarLauncher";
                # platforms = [ "x86_64-w64-mingw32" "x86_64-linux" ]; # great!
                maintainers = [ ];
              };
            };
          default = northstar;
        };

        devShell = cross.mkShell {
          nativeBuildInputs = with cross.buildPackages; [
            cmake
            ninja
            pkg-config
            perl

            (pkgs.writeShellApplication {
              name = "build-ns";
              text = ''
                set -e
                rm -rf build
                mkdir -p build

                cmake -B build -G Ninja \
                -DCMAKE_TOOLCHAIN_FILE=${toolchainFile} \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \

                cmake --build build
              '';
            })
          ];

          buildInputs = [
            cross.windows.mcfgthreads
            cross.windows.mingw_w64_headers
            cross.zlib
            cross.openssl
          ];
        };
      }
    );
}
