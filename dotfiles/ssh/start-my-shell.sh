# shellcheck shell=sh

set -o errexit
set -o nounset

name="shell"
if uname -m | grep -q 'x86_64'; then
  name="${name}-x86_64"
else
  echo "This architecture isn't supported: $(uname -m)"
  exit 1
fi
if uname | grep -q Linux; then
  name="${name}-linux"
elif uname | grep -q Darwin; then
  name="${name}-darwin"
else
  echo "This system isn't supported: $(uname)"
  exit 1
fi

shell_dir="$HOME/.local/bin"
shell_path="$shell_dir/biggs-shell"
download_url="https://github.com/bigolu/dotfiles/releases/download/master/$name"
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
"./$shell_path"
