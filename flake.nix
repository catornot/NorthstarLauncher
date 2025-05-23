{
  description = "NorthstarLauncher";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    msvc-llvm = {
      url = "github:roblabla/msvc-llvm-nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      msvc-llvm,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          msvc-llvm.overlay
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
          config.permittedInsecurePackages = [
            "dotnet-sdk-6.0.428"
            "dotnet-runtime-6.0.36"
          ];
        };
        win-pkgs = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "x86_64-w64-mingw32";
            libc = "msvcrt";
          };
        };
        gcc = win-pkgs.buildPackages.wrapCC (
          win-pkgs.buildPackages.gcc-unwrapped.override ({
            threadsCross = {
              model = "win32";
              package = null;
            };
          })
        );
      in
      let
        # msbuild = pkgs.msbuild.overrideAttrs (prev: {
        #   nativeBuildInputs = with pkgs; [
        #     dotnetCorePackages.dotnet_8
        #     mono
        #     unzip
        #     makeWrapper
        #   ];
        # });

        nativeBuildInputsWindows = with win-pkgs; [
          cmake
          gcc
        ];

        nativeBuildInputsLinux = with pkgs; [
          cmake
          # libclang
          gnumake
          # msvc-toolchain
          ninja
          msbuild
          msitools
        ];

        build-ns = pkgs.writeShellApplication {
          name = "build-ns";
          runtimeInputs = nativeBuildInputsWindows ++ nativeBuildInputsLinux;
          text = ''
            cmake -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_LINKER=ldd-link -DCMAKE_CXX_FLAGS="-fuse-ld=lld-link" -G "Ninja" -B build
          '';
        };

      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        # packages = rec {
        #   northstar = pkgs.callPackage ./default.nix { pkgs = pkgs; };
        #   default = northstar;
        # };

        devShell = pkgs.mkShell rec {
          nativeBuildInputs =
            [
              build-ns
            ]
            ++ nativeBuildInputsWindows
            ++ nativeBuildInputsLinux;

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeBuildInputs + " ${pkgs.msvc-toolchain}/bin/x64";

          shellHook = ''
            # export PATH=${pkgs.msvc-toolchain}/bin/x64:$PATH
            # export PATH=${pkgs.msvc-toolchain}/kits/10/bin/10.0.18362.0/x86:$PATH
            # export PATH=${pkgs.msvc-toolchain}/kits/10/bin/10.0.18362.0/x86/rc.exe:$PATH
            # export PATH=${pkgs.msvc-toolchain}/bin/x64/clang-cl:$PATH
            # export BIN=${pkgs.msvc-toolchain}/bin/x64
            # . $BIN/msvcenv.sh
            # export CC=clang-cl
            # export CXX=clang-cl
            # export LD=lld-link
            echo 'Windows build environment loaded with MSVC toolchain'
          '';
        };
      }
    );
}
