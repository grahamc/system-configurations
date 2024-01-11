set -o errexit
set -o nounset
set -o pipefail

if [ "$1" != 'rebase' ]; then
  exit
fi

bash ./.git-hook-assets/on-change.bash
