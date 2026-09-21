#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/common.sh"

usage() {
  printf '%s\n' \
    'Usage: wallpaper.sh [IMAGE|--restore]' \
    'Choose/apply a wallpaper, compile a dark Matugen palette, persist the path, and reload consumers.'
}
[[ ${1:-} == --help ]] && { usage; exit 0; }
[[ $# -le 1 ]] || { usage >&2; exit 2; }
require matugen
require awww

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr-rice"
state_file="$state_dir/current-wallpaper"
restore=false
if [[ ${1:-} == --restore ]]; then
  restore=true
  if [[ -r $state_file ]]; then
    IFS= read -r candidate < "$state_file"
  else
    candidate="$WALLPAPER_DIR/aurora-bloom.png"
  fi
elif [[ $# == 1 ]]; then
  candidate=$1
else
  require fd
  candidate=$(fd --absolute-path --type f --color never \
    -e png -e jpg -e jpeg -e webp -e gif . "$WALLPAPER_DIR" \
    | fuzzel_dmenu --prompt='Wallpaper › ' --placeholder='Select an image') || exit 0
  [[ -n $candidate ]] || exit 0
fi

wallpaper=$(realpath -e -- "$candidate") || die "Wallpaper does not exist: $candidate"
[[ -f $wallpaper ]] || die "Not a regular file: $wallpaper"
case ${wallpaper,,} in
  *.png|*.jpg|*.jpeg|*.webp|*.gif) ;;
  *) die "Unsupported wallpaper type: $wallpaper" ;;
esac

mkdir -p -- "$GENERATED_DIR"
if ! matugen image "$wallpaper" --config "$THEME_ROOT/config.toml" --mode dark \
  --type scheme-vibrant --source-color-index 0 --fallback-color '#8b5cf6'; then
  printf '%s\n' 'Matugen failed; restoring the bundled fallback palette.' >&2
  for fallback in "$FALLBACK_DIR"/*; do
    [[ -f $fallback ]] && install -m 0644 -- "$fallback" "$GENERATED_DIR/$(basename -- "$fallback")"
  done
  die 'Palette generation failed; fallback restored'
fi

if ! awww query >/dev/null 2>&1; then
  if [[ ${HYPR_RICE_AWWW_MANAGED:-0} != 1 ]]; then
    require awww-daemon
    setsid -f awww-daemon >/dev/null 2>&1
  fi
  for _ in {1..30}; do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
  done
fi
awww query >/dev/null 2>&1 || die 'awww-daemon did not become ready'

transition=(--transition-type grow --transition-pos 0.78,0.26 --transition-duration 1.35 --transition-fps 60 --transition-bezier .22,.8,.2,1)
$restore && transition=(--transition-type none)
awww img "$wallpaper" --resize crop --filter Lanczos3 "${transition[@]}"

mkdir -p -- "$state_dir"
tmp_state=$(mktemp "$state_dir/.current-wallpaper.XXXXXX")
printf '%s\n' "$wallpaper" > "$tmp_state"
mv -f -- "$tmp_state" "$state_file"

if ! $restore; then
  "$SCRIPT_DIR/theme-reload.sh" --quiet
  notify 'Theme updated' "$(basename -- "$wallpaper")"
fi
printf 'applied: %s\n' "$wallpaper"
