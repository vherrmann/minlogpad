{ lib, stdenv }:

stdenv.mkDerivation rec {
  name = "minlogpad-static";
  src = ../frontend;

  installPhase = ''
    mkdir $out
    cp -r * $out/
  '';
}
