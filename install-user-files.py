#!/usr/bin/env python3
"""Install the reviewed Hyprland rice into the current user's XDG paths."""
from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import shutil

HOME = Path.home()
PROJECT = HOME / ".local/share/hypr-rice"
SOURCE = PROJECT / "source"
THEME = PROJECT / "theme"
CONFIG = HOME / ".config"
BIN = HOME / ".local/bin"
STAMP = dt.datetime.now().astimezone().strftime("%Y%m%d-%H%M%S")
BACKUP = HOME / ".local/state/hypr-rice/backups" / STAMP
backed_up: list[str] = []
written: list[str] = []


def backup(path: Path) -> None:
    if not (path.exists() or path.is_symlink()):
        return
    rel = path.relative_to(HOME)
    target = BACKUP / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink():
        target.symlink_to(os.readlink(path))
    elif path.is_dir():
        shutil.copytree(path, target, symlinks=True)
    else:
        shutil.copy2(path, target)
    backed_up.append(str(path))


def copy(src: Path, dst: Path, mode: int | None = None) -> None:
    backup(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink() or dst.exists():
        dst.unlink()
    shutil.copy2(src, dst)
    if mode is not None:
        dst.chmod(mode)
    written.append(str(dst))


def text(dst: Path, content: str, mode: int = 0o644) -> None:
    backup(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink() or dst.exists():
        dst.unlink()
    dst.write_text(content)
    dst.chmod(mode)
    written.append(str(dst))


def link(dst: Path, target: Path) -> None:
    backup(dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink() or dst.exists():
        dst.unlink()
    dst.symlink_to(target)
    written.append(str(dst))


# Canonical theme compiler sources and generated/fallback outputs already live
# under PROJECT/theme; the installer only makes consumer links to them.
if not THEME.exists():
    raise SystemExit(f"missing canonical theme tree: {THEME}")
for script in (THEME / "scripts").glob("*.sh"):
    script.chmod(0o755)
(THEME / "scripts/generate-wallpaper.py").chmod(0o755)

# Hyprland core and native ecosystem configuration.
for src in (SOURCE / "hypr").rglob("*"):
    if src.is_file():
        copy(src, CONFIG / "hypr" / src.relative_to(SOURCE / "hypr"))
for name in ("hyprlock.conf", "hypridle.conf", "xdph.conf"):
    copy(SOURCE / "session/hypr" / name, CONFIG / "hypr" / name)
for src in (SOURCE / "session/hypr/scripts").iterdir():
    if src.is_file():
        copy(src, CONFIG / "hypr/scripts" / src.name, 0o755)
link(CONFIG / "hypr/modules/generated_colors.lua", THEME / "generated/hyprland-colors.lua")
link(CONFIG / "hypr/generated/hyprlock.conf", THEME / "generated/hyprlock.conf")

# Permanent top Waybar.
copy(SOURCE / "waybar/config.jsonc", CONFIG / "waybar/config.jsonc")
copy(SOURCE / "waybar/style.css", CONFIG / "waybar/style.css")
copy(SOURCE / "waybar/settings.css", CONFIG / "waybar/settings.css")
link(CONFIG / "waybar/colors.css", THEME / "generated/waybar.css")

# Notifications, control center, and OSD.
quickshell_source = SOURCE / "session/quickshell/hypr-rice"
for src in sorted(quickshell_source.glob("*.qml")):
    if src.name != "Theme.qml":
        copy(src, CONFIG / "quickshell/hypr-rice" / src.name)
copy(quickshell_source / "qmldir", CONFIG / "quickshell/hypr-rice/qmldir")
link(CONFIG / "quickshell/hypr-rice/Theme.qml", THEME / "generated/quickshell-theme.qml")
copy(SOURCE / "session/swaync/config.json", CONFIG / "swaync/config.json")
copy(SOURCE / "session/swaync/style.css", CONFIG / "swaync/style.css")
link(CONFIG / "swaync/colors.css", THEME / "generated/swaync.css")
copy(SOURCE / "session/swayosd/config.toml", CONFIG / "swayosd/config.toml")
copy(SOURCE / "session/swayosd/style.css", CONFIG / "swayosd/style.css")
link(CONFIG / "swayosd/colors.css", THEME / "generated/swayosd.css")

# Portals.
copy(
    SOURCE / "session/xdg-desktop-portal/hyprland-portals.conf",
    CONFIG / "xdg-desktop-portal/hyprland-portals.conf",
)

# Launcher and terminal consume generated palette fragments.
link(CONFIG / "fuzzel/fuzzel.ini", THEME / "generated/fuzzel.ini")
text(
    CONFIG / "ghostty/config",
    """font-family = JetBrainsMono Nerd Font\nfont-size = 11\ncommand = fish\nconfig-file = /home/cynric/.local/share/hypr-rice/theme/generated/ghostty.conf\n""",
)

# GTK, Qt, icon, and cursor consistency. GTK 4/libadwaita gets its dark
# preference from org.gnome.desktop.interface color-scheme; forcing the GTK 3
# theme or gtk-application-prefer-dark-theme there emits libadwaita warnings.
gtk3_settings = """[Settings]\ngtk-theme-name=adw-gtk3-dark\ngtk-icon-theme-name=Papirus-Dark\ngtk-font-name=Inter 10\ngtk-cursor-theme-name=capitaine-cursors\ngtk-cursor-theme-size=24\ngtk-application-prefer-dark-theme=1\n"""
gtk4_settings = """[Settings]\ngtk-icon-theme-name=Papirus-Dark\ngtk-font-name=Inter 10\ngtk-cursor-theme-name=capitaine-cursors\ngtk-cursor-theme-size=24\n"""
gtk_css = '@import url("/home/cynric/.local/share/hypr-rice/theme/generated/gtk.css");\n'
text(CONFIG / "gtk-3.0/settings.ini", gtk3_settings)
text(CONFIG / "gtk-4.0/settings.ini", gtk4_settings)
for version in ("gtk-3.0", "gtk-4.0"):
    text(CONFIG / version / "gtk.css", gtk_css)
qt_config = """[Appearance]\ncolor_scheme_path=\ncustom_palette=false\nicon_theme=Papirus-Dark\nstandard_dialogs=xdgdesktopportal\nstyle=Fusion\n\n[Fonts]\nfixed=\"JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0\"\ngeneral=\"Inter,10,-1,5,50,0,0,0,0,0\"\n"""
for version in ("qt5ct", "qt6ct"):
    text(CONFIG / version / "qt5ct.conf" if version == "qt5ct" else CONFIG / version / "qt6ct.conf", qt_config)
text(HOME / ".icons/default/index.theme", "[Icon Theme]\nInherits=capitaine-cursors\n")
text(
    CONFIG / "environment.d/10-hypr-rice.conf",
    "XCURSOR_THEME=capitaine-cursors\nXCURSOR_SIZE=24\nHYPRCURSOR_THEME=capitaine-cursors\nHYPRCURSOR_SIZE=24\nTERMINAL=ghostty\nBROWSER=firefox\n",
)

# Fish + Starship without changing the login shell.
fish = CONFIG / "fish/config.fish"
old = fish.read_text() if fish.exists() else "if status is-interactive\nend\n"
begin = "# BEGIN HYPR-RICE MANAGED BLOCK"
end = "# END HYPR-RICE MANAGED BLOCK"
if begin in old and end in old:
    prefix, rest = old.split(begin, 1)
    _, suffix = rest.split(end, 1)
    old = prefix.rstrip() + "\n" + suffix.lstrip("\n")
block = f"""{begin}\n    set -gx STARSHIP_CONFIG \"{THEME}/generated/starship.toml\"\n    if test -r \"{THEME}/generated/fish-colors.fish\"\n        source \"{THEME}/generated/fish-colors.fish\"\n    end\n    starship init fish | source\n    set -g fish_greeting\n{end}\n"""
needle = "if status is-interactive\n"
if needle in old:
    merged = old.replace(needle, needle + block, 1)
else:
    merged = old.rstrip() + "\n\nif status is-interactive\n" + block + "end\n"
text(fish, merged)

# Bounded clipboard history.
text(CONFIG / "cliphist/config", "max-items 300\nmin-store-length 1\n")

# Stable commands used by binds and widgets. Theme helpers use small wrappers so
# BASH_SOURCE resolves inside the canonical script directory (not ~/.local/bin).
theme_wrappers = {
    "hypr-rice-wallpaper": "wallpaper.sh",
    "hypr-rice-theme-reload": "theme-reload.sh",
    "hypr-rice-clipboard": "clipboard-picker.sh",
    "hypr-rice-clipboard-clear": "clipboard-clear.sh",
    "hypr-rice-calculator": "calculator.sh",
    "hypr-rice-command": "command-runner.sh",
    "hypr-rice-file-search": "file-search.sh",
    "hypr-rice-web-search": "web-search.sh",
    "hypr-rice-power-menu": "power-menu.sh",
    "hypr-rice-keybinds": "keybind-cheatsheet.sh",
}
BIN.mkdir(parents=True, exist_ok=True)
for name, script in theme_wrappers.items():
    text(BIN / name, f'#!/usr/bin/env bash\nexec {THEME}/scripts/{script} "$@"\n', 0o755)

for name, target in {
    "hypr-rice-screenshot": CONFIG / "hypr/scripts/screenshot",
    "hypr-rice-recording": CONFIG / "hypr/scripts/recording-toggle",
    "hypr-rice-bluetooth": CONFIG / "hypr/scripts/bluetooth-toggle",
    "hypr-rice-session-action": CONFIG / "hypr/scripts/session-action",
}.items():
    link(BIN / name, target)

for src in sorted((SOURCE / "bin").glob("*")):
    if src.is_file():
        copy(src, BIN / src.name, 0o755)

# User-session unit ownership and drop-ins.
unit_root = PROJECT / "system/user"
for src in sorted(unit_root.rglob("*")):
    if src.is_file():
        copy(src, CONFIG / "systemd/user" / src.relative_to(unit_root))

BACKUP.mkdir(parents=True, exist_ok=True)
manifest = {
    "created": dt.datetime.now().astimezone().isoformat(),
    "backed_up": backed_up,
    "written": written,
}
(BACKUP / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"installed {len(written)} targets")
print(f"backup {BACKUP}")
