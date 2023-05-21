# shellcheck shell=sh

set -o errexit
set -o nounset

name="shell-$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
# shellcheck disable=2034
# It gets used in an `eval`
download_url="https://github.com/bigolu/dotfiles/releases/download/master/$name"

# I disable rule 2016 since I'm intentionally not expanding the variables in the string, `eval` will do that.
if command -v curl 1>/dev/null 2>&1; then
  # shellcheck disable=2016
  file_not_exists_command='! curl --head --silent --fail "$download_url" 2> /dev/null'
  # shellcheck disable=2016
  download_command='curl --fail --progress-bar --location --time-cond "$shell_path" "$download_url" --output "$shell_path"'
  # shellcheck disable=2016
  update_command='curl --fail --progress-bar --location "$download_url" --output "$shell_path"'
else
  # shellcheck disable=2016
  file_not_exists_command='! wget -q --method=HEAD "$download_url"'
  # shellcheck disable=2016
  download_command='wget --output-document "$shell_path" "$download_url"'
  update_command="$download_command"
fi

if eval "$file_not_exists_command"; then
  echo "This system isn't supported: $(uname -sm)"
  exit 1
fi

shell_dir="$HOME/.local/bin"
shell_path="$shell_dir/biggs-shell"
if [ -f "$shell_path" ]; then
  printf "Do you want to update your shell? (y/n): "
  read -r response
  if [ "$response" = y ]; then
    eval "$update_command"
    chmod +x "$shell_path"
  fi
else
  mkdir -p "$shell_dir"
  eval "$download_command"
  chmod +x "$shell_path"
fi

"$shell_path"
