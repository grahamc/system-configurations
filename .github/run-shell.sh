# shellcheck shell=sh

set -o errexit
set -o nounset

name="shell-$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
# shellcheck disable=2034
# It gets used in an `eval`
download_url="https://github.com/bigolu/dotfiles/releases/download/master/$name"

if command -v curl 1>/dev/null 2>&1; then
  # shellcheck disable=2016
  file_not_exists_command='! curl --head --silent --fail "$download_url" 2> /dev/null'
  # shellcheck disable=2016
  download_command='curl --fail --progress-bar --location "$download_url" --output "$name"'
else
  # shellcheck disable=2016
  file_not_exists_command='! wget -q --method=HEAD "$download_url"'
  # shellcheck disable=2016
  download_command='wget --output-document "$name" "$download_url"'
fi

if eval "$file_not_exists_command"; then
  echo "This system isn't supported: $(uname -sm)"
  exit 1
fi

eval "$download_command"

chmod +x "$name"

"./$name" "$@"
