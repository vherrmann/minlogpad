{
  outputs = { self, ... }: {
    nixosModules.container = ./backend/container.nix;
  };
}
