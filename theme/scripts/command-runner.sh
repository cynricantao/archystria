#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"
usage() { printf '%s\n' 'Usage: command-runner.sh' 'Enter a Fish command and run it in a new interactive Ghostty window.'; }
[[ ${1:-} == --help ]] && { usage; exit 0; }
[[ $# == 0 ]] || { usage >&2; exit 2; }
require ghostty
require fish
command_text=$(printf '' | fuzzel_dmenu --prompt='Run › ' --placeholder='Enter a command') || exit 0
[[ -n $command_text ]] || exit 0
setsid -f ghostty -e fish -C "$command_text"
