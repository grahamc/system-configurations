# shellcheck shell=sh

set -o errexit
set -o nounset

abort() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

get_dependency() {
  for command in "$@"; do
    if command -v "$command" 1>/dev/null 2>&1; then
      printf '%s' "$command"
      return
    fi
  done
  abort "Unable to find at least one of these commands: $*"
}

fetcher="$(get_dependency curl wget)"
case "$fetcher" in
curl)
  file_exists() {
    curl --head --silent --fail "$1" 1>/dev/null 2>&1
  }
  download() {
    curl --fail --progress-bar --location "$1" --output "$2"
  }
  ;;
wget)
  file_exists() {
    wget -q --method=HEAD "$1"
  }
  download() {
    wget --output-document "$2" "$1"
  }
  ;;
esac

platform="$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
release_artifact_name="$1-$platform"
release_artifact_url="https://github.com/bigolu/system-configurations/releases/download/v0.0.1/$release_artifact_name"

if ! file_exists "$release_artifact_url"; then
  abort "Your platform isn't supported: $platform"
fi

download "$release_artifact_url" "$release_artifact_name"
chmod +x "$release_artifact_name"
# The command in my README pipes this script into sh so we need to set stdin back to the terminal
exec "./$release_artifact_name" </dev/tty
