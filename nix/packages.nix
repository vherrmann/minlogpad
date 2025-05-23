{ inputs, isOnline, ... }:
{ pkgs, ... }:
let
  minlog = pkgs.callPackage (import ./minlog.nix { inherit (inputs) minlogSrc; }) { };
  minlogpad-backend = pkgs.callPackage (import ../backend/package.nix) { };
  minlogpad-frontend = pkgs.callPackage (import ../frontend/package.nix { inherit minlog; }) { };

  sharedEmacsPkgs = (
    epkgs: with epkgs; [
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
    ]
  );
  linkMinlogPathToEmacs =
    epk:
    pkgs.stdenv.mkDerivation {
      name = "minlogpad";
      buildInputs = [ pkgs.makeWrapper ];
      dontUnpack = true;
      postBuild =
        ''
          mkdir -p $out/bin/
          touch /tmp/test
        ''
        + (
          if isOnline then
            ''
              makeWrapper ${epk}/bin/emacs $out/bin/minlogpad \
              --set MINLOGPATH "${minlog}/share/minlog"
            ''
          else
            let
              confDir = "/tmp/minlogpad-emacs-config";
              confFile = "${confDir}/init.el";
            in
            ''
              makeWrapper ${epk}/bin/emacs $out/bin/minlogpad \
              --set MINLOGPATH "${minlog}/share/minlog" \
              --run "mkdir ${confDir} -p" \
              --run "([ ! -f ${confFile} ] || [ -L ${confFile} ]) \
                     && ln -fs ${minlogpad-backend}/skeleton-home-shared/.emacs \
                               ${confFile}" \
              --add-flags "--init-directory ${confDir}"
            ''
        );
    };
  emacsWithMinlog = linkMinlogPathToEmacs (
    pkgs.emacs.pkgs.withPackages (
      epkgs:
      sharedEmacsPkgs epkgs
      ++ [
        epkgs.polymode
        epkgs.markdown-mode
      ]
    )
  );
  emacsWithMinlogNoX = linkMinlogPathToEmacs (pkgs.emacs-nox.pkgs.withPackages sharedEmacsPkgs);
in
{
  inherit
    minlog
    minlogpad-backend
    minlogpad-frontend
    emacsWithMinlog
    emacsWithMinlogNoX
    ;
}
