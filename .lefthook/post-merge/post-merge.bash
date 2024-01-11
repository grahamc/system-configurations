set -o errexit
set -o nounset
set -o pipefail

bash ./.git-hook-assets/on-change.bash
