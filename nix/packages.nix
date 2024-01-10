{ inputs, isOnline, ... }:
{ pkgs, ... }:
let
  minlog =
    pkgs.callPackage (import ./minlog.nix { inherit (inputs) minlogSrc; }) { };
  minlogpad-backend = pkgs.callPackage (import ../backend/package.nix) { };
  minlogpad-frontend =
    pkgs.callPackage (import ../frontend/package.nix { inherit minlog; }) { };

  sharedEmacsPkgs = (epkgs:
    with epkgs; [
      # core
      evil
      tramp-theme
      ahungry-theme
      color-theme-sanityinc-tomorrow
      pdf-tools

      # convenience
      which-key
      undo-fu

      # scheme
      geiser
      geiser-chez
      macrostep-geiser
      paredit
      corfu
      rainbow-delimiters

      # minlog
      minlog
    ]);
  linkMinlogPathToEmacs = epk:
    pkgs.symlinkJoin {
      name = "emacs";
      paths = [ epk ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = if isOnline then ''
        wrapProgram $out/bin/emacs \
        --set MINLOGPATH "${minlog}/share/minlog"
      '' else ''
        wrapProgram $out/bin/emacs \
        --set MINLOGPATH "${minlog}/share/minlog" \
        --run "mkdir /tmp/minlogpad-emacs-config -p" \
        --run "cp -u ${minlogpad-backend}/skeleton-home-shared/.emacs /tmp/minlogpad-emacs-config/init.el" \
        --add-flags "--init-directory /tmp/minlogpad-emacs-config"
      '';
    };
  emacsWithMinlog = linkMinlogPathToEmacs (pkgs.emacs29.pkgs.withPackages
    (epkgs: sharedEmacsPkgs epkgs ++ [ epkgs.polymode epkgs.markdown-mode ]));
  emacsWithMinlogNoX =
    linkMinlogPathToEmacs (pkgs.emacs29-nox.pkgs.withPackages sharedEmacsPkgs);
in {
  inherit minlog minlogpad-backend minlogpad-frontend emacsWithMinlog
    emacsWithMinlogNoX;
}
