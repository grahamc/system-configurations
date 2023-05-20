# shellcheck shell=sh

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

download_url="https://github.com/bigolu/dotfiles/releases/download/master/$name"
if command -v curl 1>/dev/null 2>&1; then
  curl --fail --progress-bar --location "$download_url"
else
  wget "$download_url"
fi
chmod +x "$name"

"$name" "$@"
