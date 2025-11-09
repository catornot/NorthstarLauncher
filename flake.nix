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
        win-gcc = win-pkgs.buildPackages.wrapCC (
          win-pkgs.buildPackages.gcc-unwrapped.override {
            threadsCross = {
              model = "win32";
              package = win-pkgs.windows.crossThreadsStdenv;
            };
          }
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

        buildInputsWindows = with win-pkgs; [
          # windows.mingw_w64_headers
          # windows.mcfgthreads
          # windows.mingw_w64_pthreads
          # windows.pthreads
          # windows.crossThreadsStdenv
        ];

        nativeBuildInputsWindows = with win-pkgs; [
          win-gcc
        ];

        nativeBuildInputsLinux = with pkgs; [
          # perl
          # cmake
          # libclang
          # gnumake
          # msvc-toolchain
          # ninja
          # msbuild
          # msitools
          # pkg-config
          wine
          msitools
          cmake
          ninja
          samba
          libunwind
        ];

        build-ns = pkgs.writeShellApplication {
          name = "build-ns";
          runtimeInputs = nativeBuildInputsWindows ++ nativeBuildInputsLinux;

          # -DCMAKE_CXX_COMPILER_WORKS=1 -DENABLE_THREADED_RESOLVER="OFF" -DCMAKE_C_COMPILER_WORKS=1
          text = ''

            cmake -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_LINKER=ldd-link -DCMAKE_CXX_FLAGS="-fuse-ld=lld-link" -G "Ninja" -B build
          '';
          #        text = ''
          #        	# for some reason libcurl can't find Threads
          # cmake . -G "Ninja" -B build -DENABLE_THREADED_RESOLVER="OFF"
          # cmake --build build/
          #        '';
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

          buildInputs = buildInputsWindows;

          # LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeBuildInputs + " ${pkgs.msvc-toolchain}/bin/x64";
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputsWindows;

          shellHook = ''
            export PATH=${pkgs.msvc-toolchain}/bin/x64:$PATH
            export PATH=${pkgs.msvc-toolchain}/kits/10/bin/10.0.18362.0/x86:$PATH
            export PATH=${pkgs.msvc-toolchain}/kits/10/bin/10.0.18362.0/x86/rc.exe:$PATH
            export PATH=${pkgs.msvc-toolchain}/bin/x64/clang-cl:$PATH
            export BIN=${pkgs.msvc-toolchain}/bin/x64
            # export PATH=${win-pkgs.windows.mingw_w64_pthreads}/lib:$PATH
            . $BIN/msvcenv.sh
            export CC=clang-cl
            export CXX=clang-cl
            export LD=lld-link
            export CC=gcc
            export CXX=g++
            export LD=ld
            echo 'Windows build environment loaded with MSVC toolchain'
          '';
        };
      }
    );
}
