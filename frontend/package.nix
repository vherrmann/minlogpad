{ minlog-package, ... }:
{ lib, stdenv }:

stdenv.mkDerivation rec {
  name = "minlogpad-frontend";
  src = ./.;

  installPhase = ''
    mkdir $out
    cp -r * $out/
    find $out -type f -print0 | xargs -0 sed -i -e "s:@MINLOG_VERSION@:${minlog-package.version}:g"
  '';
}
