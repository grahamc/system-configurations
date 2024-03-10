set -o errexit
set -o nounset
set -o pipefail

# verify flake output format and build packages
NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure

# build devShells
nix flake show --json |
  jq ".devShells.\"$(nix show-config system)\"|keys[]" |
  xargs -I {} nix develop .#{} --command bash -c ':'

# build bundles
temp="$(mktemp --directory)"
trap 'rm -rf $temp' SIGINT SIGTERM ERR EXIT
nix bundle --out-link "$temp/shell" --bundler .# .#shell
NIXPKGS_ALLOW_UNFREE=1 nix bundle --impure --out-link "$temp/terminal" --bundler .# .#terminal

# Do this last to avoid being rate-limited by BitWarden
just get-secrets
