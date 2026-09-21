#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"
usage() { printf '%s\n' 'Usage: clipboard-clear.sh' 'Clear cliphist only after an explicit confirmation.'; }
[[ ${1:-} == --help ]] && { usage; exit 0; }
[[ $# == 0 ]] || { usage >&2; exit 2; }
require cliphist
confirmation=$(printf '%s\n' 'Clear clipboard history' 'Cancel' | fuzzel_dmenu --prompt='Confirm › ' --lines=2 --only-match) || exit 0
[[ $confirmation == 'Clear clipboard history' ]] || exit 0
cliphist wipe
notify 'Clipboard' 'History cleared'
