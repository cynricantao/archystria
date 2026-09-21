#!/usr/bin/env python3
"""Static acceptance checks for the installed Hyprland desktop configuration."""
from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tomllib

HOME = Path.home()
CFG = HOME / ".config"
PROJECT = HOME / ".local/share/hypr-rice"
failures: list[str] = []


def check(value: bool, label: str) -> None:
    if value:
        print(f"PASS {label}")
    else:
        print(f"FAIL {label}")
        failures.append(label)


def command(args: list[str], label: str, env: dict[str, str] | None = None) -> None:
    proc = subprocess.run(args, text=True, capture_output=True, env=env)
    check(proc.returncode == 0, label)
    if proc.returncode:
        print((proc.stdout + proc.stderr).strip())


def jsonc(path: Path) -> dict:
    text = re.sub(r"^\s*//.*$", "", path.read_text(), flags=re.MULTILINE)
    return json.loads(text)


waybar = jsonc(CFG / "waybar/config.jsonc")
check(waybar.get("position") == "top", "Waybar is permanently at top")
check(waybar.get("mode") == "dock" and waybar.get("exclusive") is True, "Waybar reserves an exclusive dock zone")
check(waybar.get("on-sigusr1") == "noop" and waybar.get("on-sigusr2") == "reload" and waybar.get("reload_style_on_change") is not True, "Waybar signal/style reload policy")
modules = waybar["modules-left"] + waybar["modules-center"] + waybar["modules-right"]
for removed in ("battery", "backlight", "tray", "network", "bluetooth", "wireplumber#source", "wireplumber#sink", "cpu", "temperature"):
    check(removed not in modules, f"Waybar omits persistent clutter: {removed}")
for required in ("custom/launcher", "ext/workspaces", "hyprland/window", "mpris", "custom/caffeinate", "custom/network", "custom/control-center", "custom/clock", "custom/power"):
    check(required in modules, f"Waybar module {required}")
check(waybar.get("height", 99) <= 30 and all(waybar.get(key, 0) == 0 for key in ("margin-top", "margin-left", "margin-right")), "Waybar is a slim integrated menu bar")
check(waybar.get("ext/workspaces", {}).get("on-click") == "activate", "workspace clicks use the compositor protocol")

quickshell_dir = CFG / "quickshell/hypr-rice"
qml_text = "\n".join(path.read_text() for path in quickshell_dir.glob("*.qml"))
check(qml_text.count("NotificationServer {") == 1, "Quickshell has exactly one notification server")
for feature in ("RECENT", "YESTERDAY", "OLDER", "actionsSupported: true", "markAllRead", "toggleNotifications"):
    check(feature in qml_text, f"Quickshell notification feature: {feature}")
control_center_text = (quickshell_dir / "ControlCenter.qml").read_text()
duplicate_session_labels = ('text: "Lock"', 'text: "Suspend"', 'text: "Logout"', 'text: "Restart"', 'text: "Power"')
check(control_center_text.count("session-action") == 1 and all(label not in control_center_text for label in duplicate_session_labels), "Control Center has one lock action and no duplicate session menu")
check("systemctl poweroff" not in qml_text and "systemctl reboot" not in qml_text, "Quickshell has no direct dangerous power action")
session_target = (CFG / "systemd/user/hypr-rice-session.target").read_text()
check("hypr-rice-quickshell.service" in session_target and "swaync.service" not in session_target, "Quickshell is the sole session notification owner")

tomllib.loads((CFG / "swayosd/config.toml").read_text())
check(True, "SwayOSD TOML parses")

expected_links = {
    CFG / "waybar/colors.css": PROJECT / "theme/generated/waybar.css",
    CFG / "swaync/colors.css": PROJECT / "theme/generated/swaync.css",
    CFG / "swayosd/colors.css": PROJECT / "theme/generated/swayosd.css",
    CFG / "fuzzel/fuzzel.ini": PROJECT / "theme/generated/fuzzel.ini",
    CFG / "hypr/modules/generated_colors.lua": PROJECT / "theme/generated/hyprland-colors.lua",
    CFG / "hypr/generated/hyprlock.conf": PROJECT / "theme/generated/hyprlock.conf",
    CFG / "quickshell/hypr-rice/Theme.qml": PROJECT / "theme/generated/quickshell-theme.qml",
}
for link, target in expected_links.items():
    check(link.is_symlink() and link.resolve() == target.resolve() and target.is_file(), f"generated fragment link {link.relative_to(HOME)}")

for executable in (
    "Hyprland", "waybar", "fuzzel", "qs", "localsend", "pavucontrol", "swayosd-client", "swayosd-server",
    "hyprlock", "hypridle", "awww", "awww-daemon", "matugen", "ghostty", "fish", "starship",
    "grim", "slurp", "wf-recorder", "wl-copy", "cliphist", "bluetoothctl", "nm-connection-editor",
):
    check(shutil.which(executable) is not None, f"command available: {executable}")

for wrapper in (
    "hypr-rice-wallpaper", "hypr-rice-theme-reload", "hypr-rice-clipboard", "hypr-rice-clipboard-clear",
    "hypr-rice-calculator", "hypr-rice-command", "hypr-rice-file-search", "hypr-rice-web-search",
    "hypr-rice-power-menu", "hypr-rice-keybinds", "hypr-rice-screenshot", "hypr-rice-recording",
    "hypr-rice-panel-data", "hypr-rice-caffeinate", "hypr-rice-pavucontrol", "hypr-rice-waybar-clock",
):
    path = HOME / ".local/bin" / wrapper
    check(path.exists() and os.access(path, os.X_OK), f"helper executable: {wrapper}")

hypr = CFG / "hypr/hyprland.lua"
command(["Hyprland", "--verify-config", "-c", str(hypr)], "Hyprland Lua configuration parses")
command(["fuzzel", "--check-config", "--config", str(CFG / "fuzzel/fuzzel.ini")], "Fuzzel configuration parses")
command(["ghostty", "+validate-config", f"--config-file={CFG / 'ghostty/config'}"], "Ghostty configuration parses")
command(["fish", "-n", str(CFG / "fish/config.fish")], "Fish configuration parses")
star_env = dict(os.environ, STARSHIP_CONFIG=str(PROJECT / "theme/generated/starship.toml"))
command(["starship", "print-config"], "Starship configuration parses", star_env)

for script in sorted((PROJECT / "theme/scripts").glob("*.sh")) + sorted((CFG / "hypr/scripts").glob("*")):
    command(["bash", "-n", str(script)], f"shell syntax: {script.name}")
command([sys.executable, "-m", "py_compile", str(PROJECT / "theme/scripts/keybind-cheatsheet.py")], "keybinding viewer Python parses")
command([sys.executable, "-m", "py_compile", str(HOME / ".local/bin/hypr-rice-panel-data"), str(HOME / ".local/bin/hypr-rice-waybar-clock")], "panel helper Python parses")
keybinds = (CFG / "hypr/modules/keybinds.lua").read_text()
check(f'local helper = "{HOME}/.local/bin/"' in keybinds and 'helper .. "hypr-rice-screenshot region"' in keybinds, "Print screenshot uses an absolute helper path")
check("hypr-rice-screenshot full" in keybinds and "hypr-rice-screenshot active" in keybinds, "full and active screenshot bindings exist")
check("Screenshot-$(date +'%Y-%m-%d-%H-%M-%S').png" in (CFG / "hypr/scripts/screenshot").read_text(), "screenshot filename convention")

check((PROJECT / "theme/wallpapers/aurora-bloom.png").is_file(), "bundled procedural wallpaper exists")
check("max-items 300" in (CFG / "cliphist/config").read_text(), "clipboard history is bounded")
check("STARSHIP_CONFIG" in (CFG / "fish/config.fish").read_text(), "Fish loads generated Starship theme")

if failures:
    print(f"FAILED: {len(failures)} check(s)")
    raise SystemExit(1)
print("PASS: installed configuration static acceptance suite")
raise SystemExit(0)
