{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation rec {
  name = "minlogpad-backend";
  src = ./.;

  installPhase = ''
    mkdir $out
    cp -r * $out/
    find $out -type f -print0 | xargs -0 sed -i -e "s:@out@:$out:g"
  '';
}
