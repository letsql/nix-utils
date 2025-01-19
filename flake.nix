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
        inherit (import ./nix/lib.nix) mkUtils;
        patches = let
          dir =./patches;
        in
          builtins.mapAttrs
          (name: _: builtins.readFile "${dir}/${name}")
          (
            pkgs.lib.attrsets.filterAttrs
            (_: value: value == "regular")
            (builtins.readDir dir)
          )
        ;
        overrides =
          builtins.mapAttrs
          (name: value: (attrs: {
            # apply the patch
            patches = (attrs.patches or []) ++ [
              (builtins.toFile name value)
            ];
            # mark as not broken
            meta = (attrs.meta or {}) // {
              broken = false;
            };
          }))
          patches
        ;
        utils = mkUtils { inherit pkgs prefix; };
        commands = import ./nix/commands.nix { inherit pkgs overrides prefix; };
      in {
        inherit patches overrides;
        apps = (utils.attrsToApps commands.commands) // {
          default = self.apps.${system}.letsql-debug-drv;
        };
        devShells = {
          inherit (commands) commands-shell;
          default = self.devShells.${system}.commands-shell;
        };
        lib = { inherit pkgs utils mkUtils; };
        programs = commands.commands;
      });
}
