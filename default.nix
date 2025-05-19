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

  src = builtins.path { path = ./.; };

  nativeBuildInputs = with pkgs; [
    docker
  ];
  buildInputs = [
  ];

  sourceRoot = builtins.path { path = ./.; };

  phases = [
    "configurePhase"
    "buildPhase"
    "installPhase"
  ];

  # doesn't work :/
  configurePhase = ''
    mkdir ${sourceRoot}/homeless-shelter
  '';

  buildPhase = ''
    docker build --rm -t northstar-build-fedora .
    docker run --rm -it -e CC=cl -e CXX=cl --mount type=bind,source="$(pwd)",destination=/build northstar-build-fedora cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Windows -G "Ninja" -B build
  '';

  installPhase = ''
    runHook preInstall
    docker run --rm -it -e CC=cl -e CXX=cl --mount type=bind,source="$(pwd)",destination=/build northstar-build-fedora cmake --build build/
    runHook postInstall
  '';

  meta = {
    description = "Northstar launcher";
    homepage = "https://northstar.tf/";
    license = lib.licenses.mit;
    mainProgram = "NorthstarLauncher";
    # platforms = [ "x86_64-w64-mingw32" "x86_64-linux" ]; # great!
    maintainers = [ ];
  };
}
