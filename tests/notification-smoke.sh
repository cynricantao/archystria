#!/usr/bin/env bash
set -euo pipefail

if [[ "${HYPR_RICE_PRIVATE_BUS:-}" != 1 ]]; then
    outer_log="$(mktemp)"
    set +e
    output="$(dbus-run-session -- env HYPR_RICE_PRIVATE_BUS=1 "$0" 2>"$outer_log")"
    status=$?
    set -e
    if [[ "$status" == 0 ]]; then
        printf 'Private-bus notification, popup, grouped-center, IPC, and unread-state smoke passed.\n'
    else
        printf '%s\n' "$output" >&2
        cp "$outer_log" /dev/stderr
    fi
    rm -f -- "$outer_log"
    exit "$status"
fi

root="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/hypr-rice"
log="$(mktemp)"
state="$(mktemp)"
pid=""
cleanup() {
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi
    rm -f -- "$log" "$state"
}
trap cleanup EXIT

HYPR_RICE_UNREAD_PATH="$state" qs -p "$root" --no-color >"$log" 2>&1 &
pid=$!

ready=0
for _ in {1..100}; do
    if qs ipc --pid "$pid" show >/dev/null 2>&1 && busctl --user status org.freedesktop.Notifications >/dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 0.05
done
if [[ "$ready" != 1 ]]; then
    printf 'Private notification server did not become ready.\n' >&2
    cp "$log" /dev/stderr
    exit 1
fi

notify-send --app-name="Quickshell validation" "Notification smoke" "Popup and grouped history"

received=0
for _ in {1..100}; do
    if [[ -s "$state" ]] && [[ "$(<"$state")" == *'"unread":1'* ]]; then
        received=1
        break
    fi
    sleep 0.05
done
if [[ "$received" != 1 ]]; then
    printf 'Notification did not update unread state.\n' >&2
    cp "$log" /dev/stderr
    exit 1
fi

qs ipc --pid "$pid" call panels toggleNotifications >/dev/null
read_state=0
for _ in {1..100}; do
    if [[ -s "$state" ]] && [[ "$(<"$state")" == *'"unread":0'* ]]; then
        read_state=1
        break
    fi
    sleep 0.05
done
qs ipc --pid "$pid" call panels closeAll >/dev/null

if [[ "$read_state" != 1 ]]; then
    printf 'Clock-style notification toggle did not mark history read.\n' >&2
    cp "$log" /dev/stderr
    exit 1
fi
if [[ "$(<"$log")" == *"Failed to load configuration"* ]] || [[ "$(<"$log")" == *"TypeError"* ]] || [[ "$(<"$log")" == *"ReferenceError"* ]]; then
    cp "$log" /dev/stderr
    exit 1
fi

printf 'Private-bus notification, popup, grouped-center, IPC, and unread-state smoke passed.\n'
