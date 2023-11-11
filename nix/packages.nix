{ inputs, ... }:
{ pkgs, ... }:
let
  minlog =
    pkgs.callPackage (import ./minlog.nix { inherit (inputs) minlogSrc; }) { };
  minlogpad-backend = pkgs.callPackage (import ../backend/package.nix) { };
  minlogpad-frontend =
    pkgs.callPackage (import ../frontend/package.nix { inherit minlog; }) { };

  sharedEmacsPkgs = (epkgs:
    let
      mygeiser = epkgs.geiser.overrideAttrs (oldAttrs: rec {
        patches = (oldAttrs.patches or [ ]) ++ [
          # https://gitlab.com/emacs-geiser/geiser/-/merge_requests/17
          ./patches/0001-fix-repl-Make-whitespace-case-more-precise.patch
        ];
      });
    in with epkgs; [
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
      mygeiser
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
      postBuild = ''
        wrapProgram $out/bin/emacs \
        --set MINLOGPATH "${minlog}/share/minlog"
      '';
    };
  emacsWithMinlog = linkMinlogPathToEmacs (pkgs.emacs.pkgs.withPackages
    (epkgs: sharedEmacsPkgs epkgs ++ [ epkgs.polymode epkgs.markdown-mode ]));
  emacsWithMinlogNoX =
    linkMinlogPathToEmacs (pkgs.emacs-nox.pkgs.withPackages sharedEmacsPkgs);
in {
  inherit minlog minlogpad-backend minlogpad-frontend emacsWithMinlog
    emacsWithMinlogNoX;
}
