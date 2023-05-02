# shellcheck shell=sh

set -o errexit
set -o nounset

shell_dir="$HOME/.local/bin"
shell_path="$shell_dir/biggs-shell"
download_url="https://github.com/bigolu/dotfiles/releases/download/master/shell"
if [ -f "$shell_path" ]; then
  printf "Do you want to update your shell? (y/n): "
  read -r response
  if [ "$response" = y ]; then
    if command -v curl; then
      curl --fail --progress-bar --location "$download_url" --output "$shell_path"
    else
      wget --output-document "$shell_path" "$download_url"
    fi
    chmod +x "$shell_path"
  fi
else
  mkdir -p "$shell_dir"
  if command -v curl; then
    curl --fail --progress-bar --location --time-cond "$shell_path" "$download_url" --output "$shell_path"
  else
    wget --output-document "$shell_path" "$download_url"
  fi
  chmod +x "$shell_path"
fi
"$shell_path"
