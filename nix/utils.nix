{ pkgs, prefix ? "" }:
rec {
  pname-or-name = drv: if drv ? "pname" then drv.pname else drv.name;

  writeShellScriptBinWithArgs = { drv, name ? pname-or-name drv, args ? [ ], append-args ? true, set-eux ? true }: let
    name' = if append-args then (builtins.concatStringsSep "-" ([ (prefix + name) ] ++ args)) else name;
    preamble = if set-eux then "set -eux" else "";
    infix = builtins.concatStringsSep " " args;
  in pkgs.writeShellScriptBin "${name'}" ''
    ${preamble}
    ${drv}/bin/${name} ${infix} "''${@}"
  '';

  drvToApp = { drv, name ? pname-or-name drv }: {
    type = "app";
    program = "${drv}/bin/${name}";
  };

  drvToAppWithArgs = { drv, name ? pname-or-name drv, args ? [ ] }: let
    drvWithArgs = writeShellScriptBinWithArgs { inherit drv name args; };
  in drvToApp { drv = drvWithArgs; };

  attrsToApps = attrs: builtins.mapAttrs (name: drv: drvToApp { inherit drv; }) attrs;
}
