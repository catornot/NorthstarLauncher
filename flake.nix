{
  description = "NorthstarLauncher - MSVC cross build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

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
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ msvc-llvm.overlay ];
          config.allowUnfree = true;
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

          ];

          buildInputs = [

            (pkgs.writeShellApplication {
              name = "build-ns";
              runtimeInputs = nativeBuildInputs;

              text = ''
                export PATH=${pkgs.msvc-toolchain}/bin/x64:$PATH
                export BIN=${pkgs.msvc-toolchain}/bin/x64
                $BIN/msvcenv.sh
                export CC=clang-cl
                export CXX=clang-cl
                export LD=lld-link
                echo 'Windows build environment loaded with MSVC toolchain'
                cmake \
                  -G Ninja \
                  -DCMAKE_SYSTEM_NAME=Windows \
                  -DCMAKE_C_COMPILER=clang-cl \
                  -DCMAKE_CXX_COMPILER=clang-cl \
                  -DCMAKE_C_FLAGS="/clang:-fuse-ld=lld" \
                  -DCMAKE_CXX_FLAGS="/clang:-fuse-ld=lld" \
                  -B build
              '';
            })
          ];

          shellHook = ''
            			export PATH=${pkgs.msvc-toolchain}/bin/x64:$PATH
            			export BIN=${pkgs.msvc-toolchain}/bin/x64
            			. $BIN/msvcenv.sh
            			export CC=clang-cl
            			export CXX=clang-cl
            			export LD=lld-link
            			echo 'Windows build environment loaded with MSVC toolchain'
                		'';
        };
      }
    );
}
