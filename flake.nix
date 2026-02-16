{
  description = "NorthstarLauncher - MSVC cross build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
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
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
          config = {
            allowUnsupportedSystem = true;
            allowUnfree = true;
            microsoftVisualStudioLicenseAccepted = true;
          };
        };

        cross = pkgs.pkgsCross.x86_64-windows;

        base = cross.windows.sdk;
        arch="x64";

        toolchainFile =
          let
            MSVC_INCLUDE = "${base}/crt/include";
            MSVC_LIB = "${base}/crt/lib";
            WINSDK_INCLUDE = "${base}/sdk/Include";
            WINSDK_LIB = "${base}/sdk/Lib";
            mkArgs = args: builtins.concatStringsSep " " args;
            linker = mkArgs [
              "/manifest:no"
              "-libpath:${MSVC_LIB}"
              "-libpath:${WINSDK_LIB}/ucrt/${arch}"
              "-libpath:${WINSDK_LIB}/um/${arch}"
              "-libpath:${WINSDK_LIB}/x64"
			  "-libpath:${MSVC_LIB}/x64"
            ];
            compiler = mkArgs [
              "/vctoolsdir ${cross.windows.sdk}/crt"
              "/winsdkdir ${cross.windows.sdk}/sdk"
              "/EHs"
              "-D_CRT_SECURE_NO_WARNINGS"
              "--target=x86_64-windows-msvc"
              "-fms-compatibility-version=19.11"
              "-imsvc ${MSVC_INCLUDE}"
              "-imsvc ${WINSDK_INCLUDE}/ucrt"
              "-imsvc ${WINSDK_INCLUDE}/shared"
              "-imsvc ${WINSDK_INCLUDE}/um"
              "-imsvc ${WINSDK_INCLUDE}/winrt"
            ];
          in
          pkgs.writeText "WindowsToolchain.cmake" ''
            set(CMAKE_SYSTEM_NAME Windows)
            set(CMAKE_SYSTEM_VERSION 10.0)
            set(CMAKE_SYSTEM_PROCESSOR x86_64)
            set(IS_NIX_ENV 1) # for a check somewhere down the line

            set(CMAKE_C_COMPILER "clang-cl")
            set(CMAKE_CXX_COMPILER "clang-cl")
            set(CMAKE_AR "llvm-lib")
            set(CMAKE_LINKER "lld-link")
            # set(CMAKE_RC_COMPILER "llvm-rc")

            set(CMAKE_C_FLAGS "${compiler}")
            set(CMAKE_CXX_FLAGS "${compiler}")
            set(CMAKE_EXE_LINKER_FLAGS "${linker}")

            set(CMAKE_C_STANDARD_LIBRARIES "${compiler}")
            set(CMAKE_CXX_STANDARD_LIBRARIES "${compiler}")
            set(CMAKE_SHARED_LINKER_FLAGS "${linker}")
            set(CMAKE_MODULE_LINKER_FLAGS "${linker}")

            set(CMAKE_C_COMPILER_WORKS 1)
            set(CMAKE_CXX_COMPILER_WORKS 1)

            message(STATUS "MSVC_LIB: ${MSVC_LIB}")
            message(STATUS "WINSDK_LIB: ${WINSDK_LIB}")

			include_directories(${MSVC_INCLUDE})
			include_directories(${WINSDK_INCLUDE}/ucrt)
			include_directories(${WINSDK_INCLUDE}/shared)
			include_directories(${WINSDK_INCLUDE}/um)
			include_directories(${WINSDK_INCLUDE}/winrt)

			set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")

            set(CMAKE_VERBOSE_MAKEFILE ON)
          '';
      in
      {
        formatter = pkgs.nixfmt-tree;

         packages = rec {
          northstar =
            pkgs.stdenv.mkDerivation {
              pname = "NorthstarLauncher";
              version = "1.31.6";
              src = ./.;

              nativeBuildInputs = [
	            cross.buildPackages.cmake
	            cross.buildPackages.ninja
	            cross.buildPackages.msitools
	            pkgs.llvmPackages.clang-unwrapped
	            pkgs.llvmPackages.bintools-unwrapped
	            pkgs.perl
	            pkgs.pkg-config
	            cross.zlib
	            cross.windows.sdk
              ];

              buildInputs = [
              ];

              cmakeFlags = [
              	"-G Ninja"
                "-DCMAKE_BUILD_TYPE=Release"
                "-DCMAKE_TOOLCHAIN_FILE=${toolchainFile}"
                "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
              ];

              meta = {
                description = "Northstar launcher";
                homepage = "https://northstar.tf/";
                license = pkgs.lib.licenses.mit;
                mainProgram = "NorthstarLauncher";
                platforms = [ "x86_64-linux" ];
                maintainers = [ ];
              };
            };
          default = northstar;
        };

        devShell = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [
            cross.buildPackages.cmake
            cross.buildPackages.ninja
            cross.buildPackages.msitools
            llvmPackages.clang-unwrapped
            llvmPackages.bintools-unwrapped
            perl
            cross.zlib
            pkg-config
            cross.windows.sdk
          ];

          buildInputs = [
            (pkgs.writeShellApplication {
              name = "build-ns";
              runtimeInputs = [ ];

              text = ''
                set -e
                rm -rf build
                mkdir -p build

                cmake -B build -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_TOOLCHAIN_FILE=${toolchainFile} \
                -DCMAKE_POLICY_VERSION_MINIMUM=3.5


                cmake --build build/
              '';
            })
          ];

        };
      }
    );
}
