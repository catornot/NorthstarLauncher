{
  description = "Northstar launcher";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/24.11";
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
        sys-pkgs = import nixpkgs { inherit system; };
        nixpkgs-attrs = {
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
        pkgs = import nixpkgs nixpkgs-attrs;
        pkgs-unstable = import nixpkgs-unstable nixpkgs-attrs;

        mkCross = pkgs: pkgs.pkgsCross.mingwW64;
        cross = mkCross pkgs;
        cross-unstable = mkCross pkgs-unstable;
        sdk = (
          # no overrides :(
          cross-unstable.windows.sdk.override {
            # lib = pkgs.lib;
            # stdenvNoCC = pkgs.stdenvNoCC;
            # testers = pkgs.testers;
            # llvmPackages = pkgs.llvmPackages;
            # callPackage = pkgs.callPackage;
            # xwin = pkgs-unstable.xwin;
          }
        );

        toolchainFile = sys-pkgs.writeText "WindowsToolchain.cmake" ''
          set(CMAKE_SYSTEM_NAME Windows)
          set(CMAKE_SYSTEM_VERSION 10.0)
          include_directories("${cross.windows.mingw_w64_headers}/include")
          set(DHAVE_IOCTLSOCKET ON)
          set(DCMAKE_REQUIRED_LIBRARIES ws2_32)
        '';
      in
      {
        formatter = sys-pkgs.nixfmt-rfc-style;
        packages = rec {
          northstar =
            with cross;
            cross.stdenv.mkDerivation {
              pname = "NorthstarLauncher";
              version = "0.0.0";
              src = builtins.path { path = self; };

              nativeBuildInputs = [
                buildPackages.cmake
                buildPackages.ninja
                buildPackages.pkg-config
                buildPackages.perl
              ];

              buildInputs = [
                cross.windows.mingw_w64_headers
                cross.windows.mingw_w64_crt
                cross.windows.pthreads
                cross.windows.sdk
                cross.zlib
                cross.openssl
              ];

              cmakeFlags = [
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
                license = sys-pkgs.lib.licenses.mit;
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

            (sys-pkgs.writeShellApplication {
              name = "build-ns";
              text = ''
                set -e
                rm -rf build
                mkdir -p build

                cmake -B build -G Ninja \
                -DCMAKE_TOOLCHAIN_FILE=${toolchainFile} \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                -DCURL_USE_WINDOWS_SOCKETS=ON \
                -DUSE_WINSOCK=ON \
                -DCMAKE_REQUIRED_LIBRARIES=ws2_32 \

                cmake --build build
              '';
            })
          ];

          buildInputs = [
            cross.windows.mingw_w64_headers
            # cross.windows.mingw_w64_crt
            cross.windows.pthreads
            sdk
            cross.zlib
            cross.openssl
          ];
        };
      }
    );
}
