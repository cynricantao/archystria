#!/usr/bin/env python3
"""Render a grouped Fuzzel cheatsheet from live Hyprland bindings."""
from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys

THEME = Path(os.environ.get("HYPR_RICE_THEME_ROOT", Path.home() / ".local/share/hypr-rice/theme"))
ORDER = ["WINDOWS", "WORKSPACES", "APPS", "SYSTEM", "NAVIGATION", "MEDIA"]
KEY_NAMES = {
    "RETURN": "Enter", "ESCAPE": "Esc", "SPACE": "Space", "TAB": "Tab",
    "SLASH": "/", "SEMICOLON": ";", "PRINT": "Print",
    "SUPER_L": "Super", "mouse_down": "Wheel down", "mouse_up": "Wheel up",
    "mouse:272": "Left drag", "mouse:273": "Right drag",
    "XF86AudioRaiseVolume": "Volume up", "XF86AudioLowerVolume": "Volume down",
    "XF86AudioMute": "Mute", "XF86AudioMicMute": "Mic mute",
    "XF86AudioPlay": "Media play", "XF86AudioPause": "Media pause",
    "XF86AudioNext": "Media next", "XF86AudioPrev": "Media previous",
}


def chord(binding: dict) -> str:
    mask = int(binding.get("modmask", 0))
    parts: list[str] = []
    for bit, name in ((64, "Super"), (4, "Ctrl"), (8, "Alt"), (1, "Shift")):
        if mask & bit:
            parts.append(name)
    raw = str(binding.get("key") or f"code:{binding.get('keycode', 0)}")
    key = KEY_NAMES.get(raw, raw.title() if len(raw) > 1 else raw.upper())
    if raw == "SUPER_L" and parts == ["Super"]:
        return "Super"
    parts.append(key)
    return " + ".join(parts)


def category(description: str) -> str:
    text = description.lower()
    if any(word in text for word in ("volume", "mute", "media", "track", "microphone")):
        return "MEDIA"
    if text.startswith("focus window") or "focus next" in text or "focus previous" in text:
        return "NAVIGATION"
    if "workspace" in text:
        return "WORKSPACES"
    if any(word in text for word in ("capture", "recording", "lock", "exit hyprland", "power menu", "notification", "do-not-disturb", "keybinding reference")):
        return "SYSTEM"
    if any(word in text for word in ("open ", "search ", "calculator", "clipboard", "wallpaper", "theme")):
        return "APPS"
    return "WINDOWS"


def load_live() -> list[dict]:
    result = subprocess.run(["hyprctl", "binds", "-j"], text=True, capture_output=True, timeout=3)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "hyprctl binds failed")
    return json.loads(result.stdout)


def build_lines(bindings: list[dict]) -> list[str]:
    groups: dict[str, list[str]] = {name: [] for name in ORDER}
    seen: set[tuple[str, str]] = set()
    aggregate = {"switch": False, "move_workspace": False, "focus": False, "move": False, "resize": False}

    for binding in bindings:
        description = str(binding.get("description") or "").removeprefix("Emergency: ")
        if not description:
            continue
        lower = description.lower()
        if lower.startswith("switch to workspace "):
            aggregate["switch"] = True
            continue
        if lower.startswith("move window to workspace "):
            aggregate["move_workspace"] = True
            continue
        if lower.startswith("focus window "):
            aggregate["focus"] = True
            continue
        if lower.startswith("move window ") and lower.rsplit(" ", 1)[-1] in {"left", "right", "up", "down"}:
            aggregate["move"] = True
            continue
        if lower.startswith("resize window "):
            aggregate["resize"] = True
            continue
        item = (chord(binding), description)
        if item in seen:
            continue
        seen.add(item)
        groups[category(description)].append(f"{item[0]}\t{item[1]}")

    if aggregate["switch"]:
        groups["WORKSPACES"].insert(0, "Super + 1…0\tSwitch workspace 1…10")
    if aggregate["move_workspace"]:
        groups["WORKSPACES"].insert(1, "Super + Shift + 1…0\tMove window to workspace 1…10")
    if aggregate["focus"]:
        groups["NAVIGATION"].insert(0, "Super + arrows / HJK;\tFocus by direction")
    if aggregate["move"]:
        groups["WINDOWS"].append("Super + Shift + arrows / HJK;\tMove window by direction")
    if aggregate["resize"]:
        groups["WINDOWS"].append("Resize mode + arrows / HJK;\tResize window")

    output: list[str] = []
    for name in ORDER:
        if not groups[name]:
            continue
        output.append(f"━━ {name} ━━")
        output.extend(groups[name])
    return output


def fallback_lines() -> list[str]:
    fallback = THEME / "keybinds.tsv"
    if not fallback.is_file():
        raise RuntimeError("live bindings and fallback key list are unavailable")
    return fallback.read_text().splitlines()


def main() -> int:
    if len(sys.argv) > 2 or (len(sys.argv) == 2 and sys.argv[1] not in {"--help", "--print"}):
        print("Usage: keybind-cheatsheet.py [--print]", file=sys.stderr)
        return 2
    if len(sys.argv) == 2 and sys.argv[1] == "--help":
        print("Usage: keybind-cheatsheet.py [--print]\nShow grouped live Hyprland shortcuts in Fuzzel.")
        return 0
    try:
        lines = build_lines(load_live())
    except (OSError, RuntimeError, subprocess.SubprocessError, json.JSONDecodeError):
        lines = fallback_lines()
    text = "\n".join(lines) + "\n"
    if len(sys.argv) == 2:
        print(text, end="")
        return 0
    config = THEME / "generated/fuzzel.ini"
    if not config.is_file():
        config = THEME / "fallback/fuzzel.ini"
    subprocess.run([
        "fuzzel", "--dmenu", "--config", str(config), "--prompt=Shortcuts › ",
        "--placeholder=Type to filter", "--lines=18", "--width=58",
    ], input=text, text=True, check=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
