{ pkgs, prefix ? "" }:
let

  utils = import ./utils.nix { inherit pkgs prefix; };

  letsql-upterm-host = utils.writeShellScriptBinWithArgs {
    drv = pkgs.upterm;
    args = [ "host" ];
  };

  letsql-upterm-session-current = utils.writeShellScriptBinWithArgs {
    drv = pkgs.upterm;
    args = [ "session" "current" ];
  };

  letsql-asciinema-play = utils.writeShellScriptBinWithArgs {
    drv = pkgs.asciinema;
    args = [ "play" ];
  };

  letsql-asciinema-rec-local =
    pkgs.writeShellScriptBin "${prefix}asciinema-rec-local"
    "	set -eux\n\n	name=\${1}\n	shift;\n	${pkgs.asciinema}/bin/asciinema rec \"\${@}\" \"\${name}\"\n";

  letsql-debug-drv-setup-script =
    pkgs.writeText "${prefix}debug-drv-setup.sh" ''
          # we must define all of this inside of "--command" for it to persist
          alias get-phases='eval echo $(typeset -f genericBuild | grep "phases=" | perl -pe "s/^\s+phases=//")'
          alias set-phases='set $(get-phases); echo "$# phases: $@"'
          alias run-next-phase='phaseName=$1; shift; realPhaseName="''${!phaseName:-$phaseName}"; runPhase $phaseName; echo next phase: $1'
          set-phases
      		echo use run-next-phase to iterate through phases
          echo next phase: $1
    '';

  letsql-debug-drv = pkgs.writeShellScriptBin "${prefix}debug-drv" ''
        set -eux

        drvPath=$1
    		name=$(
          nix-store --query --binding pname "$drvPath" 2>/dev/null || \
          nix-store --query --binding name "$drvPath" 2>/dev/null
        )
        export out=$(mktemp -d -t "nix-debug-$name.XXXXX")
        pushd "$out" || exit
        nix-shell --command "drvPath=\"$drvPath\"; source "${letsql-debug-drv-setup-script}"; return" "$drvPath"
  '';

  letsql-nix-flake-metadata-refresh =
    utils.mkNixFlakeMetadataRefresh "github:letsql/nix-utils";

  commands = {
    inherit letsql-upterm-host letsql-upterm-session-current;
    inherit letsql-asciinema-play letsql-asciinema-rec-local;
    inherit letsql-debug-drv;
    inherit letsql-nix-flake-metadata-refresh;
  };

  commands-star = pkgs.buildEnv {
    name = "commands-star";
    paths = builtins.attrValues commands;
  };

  commands-shell = pkgs.mkShell { packages = [ commands-star ]; };

in { inherit commands commands-star commands-shell; }
