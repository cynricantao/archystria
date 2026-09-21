#!/usr/bin/env bash
# Shared paths and UI helpers. Source only.
set -o pipefail

THEME_ROOT="${HYPR_RICE_THEME_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/hypr-rice/theme}"
GENERATED_DIR="$THEME_ROOT/generated"
FALLBACK_DIR="$THEME_ROOT/fallback"
WALLPAPER_DIR="${HYPR_RICE_WALLPAPER_DIR:-$THEME_ROOT/wallpapers}"

palette_file() {
  local name=$1
  if [[ -r "$GENERATED_DIR/$name" ]]; then
    printf '%s\n' "$GENERATED_DIR/$name"
  else
    printf '%s\n' "$FALLBACK_DIR/$name"
  fi
}

fuzzel_dmenu() {
  local config
  config=$(palette_file fuzzel.ini)
  fuzzel --dmenu --config "$config" "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

require() {
  have "$1" || die "Required command not found: $1"
}

notify() {
  if have notify-send; then
    notify-send --app-name="Hypr Rice" "$@"
  fi
}

die() {
  local message=$1
  printf 'error: %s\n' "$message" >&2
  notify "Theme helper" "$message"
  exit 1
}
