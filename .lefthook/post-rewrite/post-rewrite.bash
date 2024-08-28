set -o errexit
set -o nounset
set -o pipefail

# I default to rebase so this way if I try to run the hook manually (e.g.
# `lefthook run ...`), no argument will be passed, but the script will still
# run.
if [ "${1:-rebase}" != 'rebase' ]; then
  exit
fi

bash ./.git-hook-assets/on-change.bash
