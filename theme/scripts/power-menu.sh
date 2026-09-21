#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"
usage() { printf '%s\n' 'Usage: power-menu.sh' 'Choose a session power action and require explicit confirmation before execution.'; }
[[ ${1:-} == --help ]] && { usage; exit 0; }
[[ $# == 0 ]] || { usage >&2; exit 2; }

choice=$(printf '%s\n' 'Lock' 'Suspend' 'Log out' 'Reboot' 'Power off' \
  | fuzzel_dmenu --prompt='Power › ' --lines=5 --only-match) || exit 0
[[ -n $choice ]] || exit 0
confirmation=$(printf '%s\n' "Yes — $choice" 'Cancel' \
  | fuzzel_dmenu --prompt="Confirm $choice? › " --lines=2 --only-match) || exit 0
[[ $confirmation == "Yes — $choice" ]] || exit 0

case $choice in
  Lock) require hyprlock; exec hyprlock ;;
  Suspend) exec systemctl suspend ;;
  'Log out') require hyprctl; exec hyprctl dispatch exit ;;
  Reboot) exec systemctl reboot ;;
  'Power off') exec systemctl poweroff ;;
  *) die 'Unknown power action' ;;
esac
