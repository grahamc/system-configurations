set -o errexit
set -o nounset
set -o pipefail

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

# Do this last to avoid being rate-limited by BitWarden
just get-secrets
