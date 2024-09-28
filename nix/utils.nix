{ pkgs, prefix ? "" }: rec {
  pname-or-name = drv: if drv ? "pname" then drv.pname else drv.name;

  replace-slash = string: pkgs.lib.replaceStrings [ "/" ] [ "-" ] string;

  writeShellScriptBinWithArgs = { drv, bin-name ? pname-or-name drv, args ? [ ]
    , append-args ? true, set-eux ? true }:
    let
      name' = if append-args then
        (replace-slash
          (builtins.concatStringsSep "-" ([ (prefix + bin-name) ] ++ args)))
      else
        bin-name;
      preamble = if set-eux then "set -eux" else "";
      infix = builtins.concatStringsSep " " args;
    in (pkgs.writeShellScriptBin name' ''
      ${preamble}
      ${drv}/bin/${bin-name} ${infix} "''${@}"
    '').overrideAttrs { pname = name'; };

  drvToApp = { drv, name ? pname-or-name drv }: {
    type = "app";
    program = "${drv}/bin/${name}";
  };

  drvToAppWithArgs = { drv, bin-name ? pname-or-name drv, args ? [ ] }:
    let
      drvWithArgs = writeShellScriptBinWithArgs { inherit drv bin-name args; };
    in drvToApp { drv = drvWithArgs; };

  mkNixFlakeMetadataRefresh = url:
    writeShellScriptBinWithArgs {
      drv = pkgs.nix;
      args = [ "flake" "metadata" "--refresh" url ];
      append-args = true;
    };

  mkNixFlakeMetadataRefreshApp = url:
    drvToApp { drv = mkNixFlakeMetadataRefresh url; };

  attrsToApps = attrs:
    builtins.mapAttrs (name: drv: drvToApp { inherit drv; }) attrs;
}
