# nix-utils

**What**: a small collection of utilities for creating a flake with namespaced commands frequently used in a project.
**Why**: some commonly desired functionality, like creating a set of apps from an attr set, is not straightforward

## Debugging

```
pkgName=asciinema
drvPath=$(nix derivation show nixpkgs#$pkgName | nix-shell --packages jq --command "jq --raw-output keys[0]" 2>/dev/null)
nix run github:letsql/nix-utils#letsql-debug-drv "$drvPath"
```

## Examples

We frequently develop on a repo used with nix run. To save time, we'd like a tab completeable way to update its flake: `letsql-nix-flake-metadata-refresh`

We'd like to be sure we're using our project's version of asciinema and we typically only either record to a local file or play the local file: `letsql-asciinema-rec-local`, `letsql-asciinema-play`
