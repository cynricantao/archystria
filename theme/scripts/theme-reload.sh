#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"
usage() { printf '%s\n' 'Usage: theme-reload.sh [--quiet]' 'Reload running consumers of generated theme fragments where supported.'; }
[[ ${1:-} == --help ]] && { usage; exit 0; }
quiet=false
if [[ ${1:-} == --quiet ]]; then quiet=true; shift; fi
[[ $# == 0 ]] || { usage >&2; exit 2; }

reloaded=()
if have hyprctl && hyprctl reload >/dev/null 2>&1; then reloaded+=(Hyprland); fi
if systemctl --user is-active --quiet hypr-rice-quickshell.service 2>/dev/null; then
  if systemctl --user restart hypr-rice-quickshell.service; then reloaded+=(Quickshell); fi
fi
if have pkill && pkill -USR2 -x waybar >/dev/null 2>&1; then reloaded+=(Waybar); fi
if have pgrep && pgrep -x swayosd-server >/dev/null 2>&1; then
  pkill -x swayosd-server >/dev/null 2>&1 || true
  setsid -f swayosd-server >/dev/null 2>&1
  reloaded+=(SwayOSD)
fi

message='Generated files are ready; Fuzzel, Ghostty, Fish, Starship, and GTK use them on their next launch.'
if ((${#reloaded[@]})); then
  joined=$(IFS=', '; printf '%s' "${reloaded[*]}")
  message="Reloaded: $joined. $message"
fi
$quiet || notify 'Theme reload' "$message"
printf '%s\n' "$message"
