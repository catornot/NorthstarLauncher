{
  description = "a collection of plugins for northstar related to bots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
          config = {
            allowUnsupportedSystem = true;
            allowUnfree = true;
            microsoftVisualStudioLicenseAccepted = true;
          };
        };

        cross = pkgs.pkgsCross.mingw-msvcrt-x86_64;

        toolchainFile = sys-pkgs.writeText "WindowsToolchain.cmake" ''
          set(CMAKE_SYSTEM_NAME Windows)
          set(CMAKE_SYSTEM_VERSION 10.0)

          set(CMAKE_GENERATE_WINDOWS_MANIFESTS OFF)
          # set(CMAKE_CXX_COMPILER_WORKS TRUE)
          # set(CMAKE_C_COMPILER_WORKS TRUE)

          set(CMAKE_CROSSCOMPILING_EMULATOR ${sys-pkgs.wine}/bin/wine)
        '';
      in
      {
        formatter = sys-pkgs.nixfmt-tree;
        packages = rec {
          northstar =
            with cross;
            pkgs.windows.crossThreadsStdenv.mkDerivation {
              pname = "NorthstarLauncher";
              version = "0.0.0";
              src = builtins.path { path = self; };

              nativeBuildInputs = with sys-pkgs; [
                buildPackages.cmake
                buildPackages.ninja
                wine
                msitools
                perl
                pkgs.windows.sdk
                pkgs.windows.mingw_w64_headers
                pkgs.gcc
              ];

              buildPhase = ''
                mkdir -p build

                cmake -B build -G Ninja \
                  -DCMAKE_TOOLCHAIN_FILE=${toolchainFile} \
                  -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_POLICY_VERSION_MINIMUM=3.5

                cmake --build build
              '';

              installPhase = ''
                mkdir -p $out
                cp -r build/* $out/
              '';

              meta = {
                description = "Northstar launcher";
                homepage = "https://northstar.tf/";
                license = sys-pkgs.lib.licenses.mit;
                mainProgram = "NorthstarLauncher";
                # platforms = [ "x86_64-w64-mingw32" "x86_64-linux" ]; # great!
                maintainers = [ ];
              };
            };
          default = northstar;
        };

        devShell = cross.mkShell rec {
          nativeBuildInputs = [
            cross.buildPackages.cmake
            cross.buildPackages.pkg-config
            cross.buildPackages.ninja
            sys-pkgs.wine
            sys-pkgs.perl

            (sys-pkgs.writeShellApplication {
              name = "build-ns";
              text = ''
                # set -e
                # rm -rf build
                # mkdir -p build

                cmake -B build -G Ninja \
                  -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_SYSTEM_NAME=Windows \
                  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                  -DCMAKE_REQUIRED_LIBRARIES=ws2_32 \
                  -DCURL_USE_SCHANNEL=ON

                cmake --build build
              '';
            })
          ];

          buildInputs = [
            pkgs.windows.mingw_w64_headers
            pkgs.windows.pthreads
            pkgs.windows.sdk
            cross.zlib
          ];
        };
      }
    );
}
