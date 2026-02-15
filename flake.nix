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

        toolchainFile = pkgs.writeText "WindowsToolchain.cmake" ''
        	set(CMAKE_SYSTEM_NAME Windows)
			set(CMAKE_SYSTEM_VERSION 10.0)

			set(CMAKE_C_COMPILER ${pkgs.msvc-toolchain}/bin/x64/clang-cl)
			set(CMAKE_CXX_COMPILER ${pkgs.msvc-toolchain}/bin/x64/clang-cl)
			set(CMAKE_AR ${pkgs.msvc-toolchain}/bin/x64/lib.exe)
			set(CMAKE_LINKER ${pkgs.msvc-toolchain}/bin/x64/lld-link)
			set(CMAKE_RC_COMPILER /bin/true)

			set(CMAKE_C_FLAGS "/nologo")
			set(CMAKE_CXX_FLAGS "/nologo")
			set(CMAKE_EXE_LINKER_FLAGS "/DEBUG /INCREMENTAL")

			set(CMAKE_GENERATE_WINDOWS_MANIFESTS OFF)
			set(CMAKE_CXX_COMPILER_WORKS TRUE)
			set(CMAKE_C_COMPILER_WORKS TRUE)
	      '';
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
			  	set -e
			    rm -rf build
				mkdir -p build

			    # Load MSVC environment
			    export PATH=${pkgs.msvc-toolchain}/bin/x64:$PATH
			    # shellcheck disable=SC1091
			    # . ${pkgs.msvc-toolchain}/bin/x64/msvcenv.sh

			    export INCLUDE="${pkgs.msvc-toolchain}/vc/tools/msvc/14.28.29333/include;${pkgs.msvc-toolchain}/kits/10/include/10.0.18362.0/shared;${pkgs.msvc-toolchain}/kits/10/include/10.0.18362.0/ucrt;${pkgs.msvc-toolchain}/kits/10/include/10.0.18362.0/um;${pkgs.msvc-toolchain}/kits/10/include/10.0.18362.0/winrt"
				export LIB="${pkgs.msvc-toolchain}/vc/tools/msvc/14.28.29333/lib/x64;${pkgs.msvc-toolchain}/kits/10/lib/10.0.18362.0/um/x64"


              # Write toolchain file
              cat "${toolchainFile}" > build/WindowsToolchain.cmake

              # Run CMake with cross-toolchain
              cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=build/WindowsToolchain.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5

			      cmake --build build/
			  '';
			})

		];

       #    shellHook = ''
       #            export PATH=${pkgs.msvc-toolchain}/bin/x64:$PATH
			    # . ${pkgs.msvc-toolchain}/bin/x64/msvcenv.sh
       #    '';

        };
      }
    );
}

			    # Run CMake
			    # cmake \
			    #   -G Ninja \
			    #   -DCMAKE_SYSTEM_NAME=Windows \
			    #   -DCMAKE_C_COMPILER=$CC \
			    #   -DCMAKE_CXX_COMPILER=$CXX \
			    #   -DCMAKE_AR=$AR \
			    #   -DCMAKE_LINKER=$LD \
			    #   -DCMAKE_REQUIRED_LIBRARIES="Ws2_32.lib" \
			    #   -DCMAKE_C_FLAGS="/Zi /Ob0 /Od /RTC1 /clang:-fuse-ld=lld" \
			    #   -DCMAKE_CXX_FLAGS="/Zi /Ob0 /Od /RTC1 /clang:-fuse-ld=lld" \
			    #   -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
			    #   -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
			    #   -B build
