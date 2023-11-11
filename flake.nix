{
  inputs = {
    minlogSrc.url =
      "git+https://www.math.lmu.de/~minlogit/git/minlog.git?ref=dev";
    minlogSrc.flake = false;

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ ];
        pkgs = import nixpkgs { inherit overlays system; };

        packages = import ./nix/packages.nix {
          inherit inputs;
          isOnline = false;
        } { inherit pkgs; };
        lib = flake-utils.lib;
      in {
        packages = {
          inherit (packages)
            minlog minlogpad-backend minlogpad-frontend emacsWithMinlog
            emacsWithMinlogNoX;
          default = packages.emacsWithMinlog;
        };

        apps = {
          emacsWithMinlog = lib.mkApp { drv = packages.emacsWithMinlog; };
          emacsWithMinlogNoX = lib.mkApp { drv = packages.emacsWithMinlogNoX; };
          default = self.apps."${system}".emacsWithMinlog;
        };
      }) // {
        nixosModules.container = import ./nix/container.nix { inherit inputs; };
        nixosConfigurations.container = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ self.nixosModules.container ];
        };
      };
}
