#!/usr/bin/env bash
set -euo pipefail

root="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/hypr-rice"
log="$(mktemp)"
state="$(mktemp)"
trap 'rm -f -- "$log" "$state"' EXIT

set +e
DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/hypr-rice-validation-no-bus" \
HYPR_RICE_UNREAD_PATH="$state" \
timeout 3s qs -p "$root" --no-color >"$log" 2>&1
status=$?
set -e

output="$(<"$log")"
if [[ "$status" != 124 ]] || [[ "$output" != *"Configuration Loaded"* ]] || [[ "$output" == *"Failed to load configuration"* ]]; then
    printf '%s\n' "$output" >&2
    printf 'Quickshell validation failed (status %s).\n' "$status" >&2
    exit 1
fi

printf 'Quickshell 0.3.1 loaded the active configuration in isolated-D-Bus mode.\n'
