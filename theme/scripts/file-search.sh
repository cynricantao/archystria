#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"
usage() { printf '%s\n' 'Usage: file-search.sh [ROOT]' 'Search files below ROOT (default: HOME) and open the selected file with xdg-open.'; }
[[ ${1:-} == --help ]] && { usage; exit 0; }
[[ $# -le 1 ]] || { usage >&2; exit 2; }
require fd
require xdg-open
root=${1:-$HOME}
[[ -d $root ]] || die "Search root is not a directory: $root"
selection=$(fd --absolute-path --type f --color never --exclude .git --exclude .cache --exclude .local/share/Trash . "$root" \
  | fuzzel_dmenu --prompt='Files › ' --placeholder="Search under $root") || exit 0
[[ -n $selection ]] || exit 0
[[ -f $selection ]] || die 'Selected file no longer exists'
setsid -f xdg-open "$selection" >/dev/null 2>&1
