#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"
usage() { printf '%s\n' 'Usage: clipboard-picker.sh' 'Pick a cliphist entry with Fuzzel and copy its decoded value to the Wayland clipboard.'; }
[[ ${1:-} == --help ]] && { usage; exit 0; }
[[ $# == 0 ]] || { usage >&2; exit 2; }
require cliphist
require wl-copy
selection=$(cliphist list | fuzzel_dmenu --prompt='Clipboard › ' --placeholder='Search history') || exit 0
[[ -n $selection ]] || exit 0
printf '%s\n' "$selection" | cliphist decode | wl-copy
notify 'Clipboard' 'Selection copied'
