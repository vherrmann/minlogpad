{
  inputs = {
    minlogSrc.url = "git+https://www.math.lmu.de/~minlogit/git/minlog.git";
    minlogSrc.flake = false;
  };
  outputs = { self, ... }@inputs: {
    nixosModules.container = import ./backend/container.nix { inherit inputs; };
  };
}
