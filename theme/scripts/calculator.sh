#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"
usage() { printf '%s\n' 'Usage: calculator.sh' 'Enter a libqalculate expression, show the result, and copy it to the Wayland clipboard.'; }
[[ ${1:-} == --help ]] && { usage; exit 0; }
[[ $# == 0 ]] || { usage >&2; exit 2; }
require qalc
require wl-copy
expression=$(printf '' | fuzzel_dmenu --prompt='Calculate › ' --placeholder='e.g. 249 * 18%') || exit 0
[[ -n $expression ]] || exit 0
if ! result=$(qalc --terse "$expression" 2>&1); then
  notify 'Calculator error' "$result"
  exit 1
fi
printf '%s' "$result" | wl-copy
printf '%s\n' "$result" | fuzzel_dmenu --prompt='Result (copied) › ' --lines=1 >/dev/null || true
