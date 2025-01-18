{
  stdenv,
  lib,
  pkgs,
  pkgsCross,
}:
let
in
stdenv.mkDerivation rec {
  pname = "NorthstarLauncher";
  version = "0.0.0";

  src = ./.;

  nativeBuildInputs = [
    pkgsCross.mingwW64.buildPackages.cmake
    pkgsCross.mingwW64.buildPackages.pkg-config
    pkgsCross.mingwW64.buildPackages.ninja
    pkgsCross.mingwW64.buildPackages.lld
    pkgsCross.mingwW64.buildPackages.bintools
  ];
  buildInputs = with pkgs; [
    pkg-config
    openssl
  ];

  sourceRoot = builtins.path { path = ./.; };

  # buildDir = ".";

  phases = [
    "configurePhase"
    "buildPhase"
    "installPhase"
  ];

  configurePhase = ''
    mkdir ./build
    cmake ${sourceRoot} -G "Ninja" -B ./build
  '';

  buildPhase = ''
    cmake --build ${sourceRoot}
  '';

  # installPhase = ''
  #   runHook preInstall
  #   mkdir -p $out/bin
  #   install -m755 -D ${src} $out/bin/papa
  #   runHook postInstall
  # '';

  # buildPhase = ''
  #   cd ${sourceRoot}
  #   cmake . -G "Ninja" -B /build
  #   cmake --build /build/
  # '';

  # Specify cmake flags
  cmakeFlags = [
    "-G Ninja"
    "-B /"
  ];

  meta = {
    description = "Northstar launcher";
    homepage = "https://northstar.tf/";
    license = lib.licenses.mit;
    mainProgram = "NorthstarLauncher";
    # platforms = [ "x86_64-w64-mingw32" "x86_64-linux" ]; # great!
    maintainers = [ ];
  };
}
