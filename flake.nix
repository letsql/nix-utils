{
  description = "Frequently used nix utilities and commands like drv debugging";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        prefix = "letsql-";
        pkgs = nixpkgs.legacyPackages.${system};
        utils = import ./nix/utils.nix { inherit pkgs prefix; };
        commands = import ./nix/commands.nix { inherit pkgs prefix; };
      in
      {
        apps = (utils.attrsToApps commands.commands) // {
          default = self.apps.${system}.letsql-debug-drv;
        };
        devShells = {
          inherit (commands) commands-shell;
          default = self.devShells.${system}.commands-shell;
        };
        lib = {
          inherit pkgs utils;
        };
        programs = commands.commands;
      });
}
