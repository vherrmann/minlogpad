{ minlogSrc, ... }:
{ pkgs, lib, stdenv, ... }:

# FIXME: add chez & emacs to runtime env
stdenv.mkDerivation {
  name = "minlog";
  version = "4a9a1e4";
  src = minlogSrc;
  buildInputs = with pkgs; [ chez which texlive.combined.scheme-medium ];
  makeFlags = [ "DESTDIR=$(out)" ];
}
