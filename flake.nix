{
  description = "NorthstarLauncher - MSVC cross build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-win.url = "github:NixOS/nixpkgs/nixos-24.11";

    flake-utils.url = "github:numtide/flake-utils";

    msvc-llvm = {
      url = "github:roblabla/msvc-llvm-nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,

      nixpkgs-win,
      flake-utils,
      msvc-llvm,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ msvc-llvm.overlay ];
          config = {
            allowUnsupportedSystem = true;
            allowUnfree = true;
          };
        };
        win-pkgs = import nixpkgs-win {
          inherit system;
          crossSystem = {
            config = "x86_64-w64-mingw32";
            libc = "msvcrt";
          };
          config = {
            allowUnsupportedSystem = true;
            allowUnfree = true;
          };
        };
      in
      {
        formatter = pkgs.nixfmt-tree;

        devShell = pkgs.mkShell rec {
          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            wine
            msitools
            samba
            msvc-toolchain
            perl
            win-pkgs.windows.pthreads
          ];

          #      buildInputs = [

          #        (pkgs.writeShellApplication {
          #          name = "build-ns";
          #          runtimeInputs = nativeBuildInputs;

          #          text = ''
          #            # ${pkgs.msvc-toolchain}/bin/x64/msvcenv.sh
          #            cmake \
          #              -G Ninja \
          #              -DCMAKE_SYSTEM_NAME=Windows \
          #              -DCMAKE_C_COMPILER=${pkgs.msvc-toolchain}/bin/x64/clang-cl \
          #              -DCMAKE_CXX_COMPILER=${pkgs.msvc-toolchain}/bin/x64/clang-cl \
          #              -DCMAKE_AR=${pkgs.msvc-toolchain}/bin/x64/llvm-lib \
          #              -DCMAKE_C_FLAGS="/clang:-fuse-ld=lld" \
          #              -DCMAKE_CXX_FLAGS="/clang:-fuse-ld=lld" \
          #  -DCMAKE_TRY_COMPILE_TARGET_TYPE=EXECUTABLE \
          #  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
          #  -DCMAKE_CROSSCOMPILING=TRUE \
          #              -DCURL_DISABLE_LDAP=TRUE \
          #              -DCURL_DISABLE_RTSP=TRUE \
          #              -DCURL_DISABLE_DICT=TRUE \
          #              -DCURL_USE_WIN32_LARGE_FILES=TRUE \
          #              -DCURL_STATICLIB=TRUE \
          #              -B build
          # '';
          #        })
          #      ];
          buildInputs = [
            (pkgs.writeShellApplication {
              name = "build-ns";
              runtimeInputs = nativeBuildInputs;

              text = ''
                                # Load MSVC environment
                                export PATH=${pkgs.msvc-toolchain}/bin/x64:$PATH
                                BIN=${pkgs.msvc-toolchain}/bin/x64
                                # shellcheck disable=SC1091
                                . $BIN/msvcenv.sh

                                export CC=clang-cl
                                export CXX=clang-cl
                                export AR=llvm-lib
                                export LD=lld-link

                                echo "Windows cross-build environment loaded with MSVC toolchain"

                                # Configure project
                                cmake -G Ninja \
                				  -DCMAKE_SYSTEM_NAME=Windows \
                				  -DCMAKE_C_COMPILER=clang-cl \
                				  -DCMAKE_CXX_COMPILER=clang-cl \
                				  -DCMAKE_AR=llvm-lib \
                				  -DCMAKE_LINKER=lld-link \
                				  -DCMAKE_REQUIRED_LIBRARIES="Ws2_32.lib" \
                				  -DCMAKE_REQUIRED_INCLUDES="$INCLUDE" \
                				  -DCMAKE_CROSSCOMPILING=TRUE \
                				  -DCURL_DISABLE_LDAP=TRUE \
                				  -DCURL_DISABLE_RTSP=TRUE \
                				  -DCURL_DISABLE_DICT=TRUE \
                				  -DCURL_USE_WIN32_LARGE_FILES=TRUE \
                				  -DCURL_STATICLIB=TRUE \
                				  -DZLIB_LIBRARY=${win-pkgs.zlib}/lib/libz.a \
                				  -DZLIB_INCLUDE_DIR=${win-pkgs.zlib}/include \
                				  -B build
              '';
            })
          ];

          shellHook = ''
            			export PATH=${pkgs.msvc-toolchain}/bin/x64:$PATH
          '';
        };
      }
    );
}
