{
  inputs = {
    minlogSrc.url =
      "git+https://www.math.lmu.de/~minlogit/git/minlog.git?ref=dev";
    minlogSrc.flake = false;
  };
  outputs = { self, ... }@inputs: {
    nixosModules.container = import ./nix/container.nix { inherit inputs; };
  };
}
