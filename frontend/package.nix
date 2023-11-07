{ lib, stdenv }:

stdenv.mkDerivation rec {
  name = "minlogpad-frontend";
  src = ./.;

  installPhase = ''
    mkdir $out
    cp -r * $out/
  '';
}
