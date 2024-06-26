{ minlogSrc, ... }:
{ pkgs, lib, stdenv, ... }:

# FIXME: add emacs to runtime env
stdenv.mkDerivation {
  name = "minlog";
  version = "${minlogSrc.shortRev}";
  src = minlogSrc;
  patches = [ ./patches/0001-On-master-fix-minlog-mode.patch ];
  buildInputs = with pkgs; [ chez which texlive.combined.scheme-medium ];
  makeFlags = [ "DESTDIR=$(out)" ];
}
