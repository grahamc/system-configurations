set -o errexit
set -o nounset
set -o pipefail

newline='
'
export NIX_CONFIG="${NIX_CONFIG}${newline}allow-import-from-derivation = true"

just check

# verify flake output format and build packages
nix flake check

# build devShells
nix flake show --json |
  jq ".devShells.\"$(nix show-config system)\"|keys[]" |
  xargs -I {} nix develop .#{} --command bash -c ':'

# build bundles
temp="$(mktemp --directory)"
trap 'rm -rf $temp' SIGINT SIGTERM ERR EXIT
nix bundle --out-link "$temp/shell" --bundler .# .#shell
nix bundle --out-link "$temp/terminal" --bundler .# .#terminal
