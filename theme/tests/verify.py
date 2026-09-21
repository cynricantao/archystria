#!/usr/bin/env python3
"""Structural and syntax checks for the canonical theme architecture."""
from __future__ import annotations

import configparser
import os
import pathlib
import struct
import subprocess
import tomllib

ROOT = pathlib.Path(__file__).resolve().parents[1]
TEMPLATES = {
    "waybar.css",
    "swaync.css",
    "swayosd.css",
    "fuzzel.ini",
    "quickshell-theme.qml",
    "ghostty.conf",
    "hyprlock.conf",
    "hyprland-colors.lua",
    "gtk.css",
    "fish-colors.fish",
    "starship.toml",
}
SCRIPTS = {
    "wallpaper.sh",
    "clipboard-picker.sh",
    "clipboard-clear.sh",
    "calculator.sh",
    "command-runner.sh",
    "file-search.sh",
    "web-search.sh",
    "power-menu.sh",
    "keybind-cheatsheet.sh",
    "theme-reload.sh",
}


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)
    print(f"ok: {message}")


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)


def main() -> int:
    expected = {
        "README.md",
        "config.toml",
        "keybinds.tsv",
        "scripts/common.sh",
        "scripts/generate-wallpaper.py",
        "scripts/keybind-cheatsheet.py",
        "wallpapers/aurora-bloom.png",
    }
    expected |= {f"scripts/{name}" for name in SCRIPTS}
    expected |= {f"templates/{name}" for name in TEMPLATES}
    expected |= {f"generated/{name}" for name in TEMPLATES}
    expected |= {f"fallback/{name}" for name in TEMPLATES}
    for relative in sorted(expected):
        check((ROOT / relative).is_file(), f"present: {relative}")

    for script in sorted((ROOT / "scripts").glob("*.sh")):
        text = script.read_text()
        check("eval " not in text, f"no eval: {script.name}")
        result = run("bash", "-n", str(script))
        check(result.returncode == 0, f"bash syntax: {script.name}: {result.stderr.strip()}")
    check("XDG_DATA_HOME" in (ROOT / "scripts/common.sh").read_text(), "helpers honor XDG_DATA_HOME")

    for py in (ROOT / "scripts/generate-wallpaper.py", ROOT / "scripts/keybind-cheatsheet.py"):
        try:
            compile(py.read_text(), str(py), "exec")
        except SyntaxError as exc:
            raise AssertionError(f"python syntax: {py.name}: {exc}") from exc
        check(True, f"python syntax: {py.name}")

    for name in sorted(SCRIPTS):
        script = ROOT / "scripts" / name
        check(bool(script.stat().st_mode & 0o111), f"executable: {name}")
        result = run(str(script), "--help")
        check(result.returncode == 0, f"help smoke test: {name}: {result.stderr.strip()}")

    config = tomllib.loads((ROOT / "config.toml").read_text())
    check(config.get("config", {}).get("fallback_color") == "#8b5cf6", "Matugen fallback color is set")
    check(config.get("config", {}).get("wallpaper", {}).get("set") is False, "Matugen wallpaper side effect is disabled")
    tables = config.get("templates", {})
    check(set(tables) == {p.rsplit(".", 1)[0].replace("-", "_") for p in TEMPLATES}, "Matugen template table set")
    for name, table in tables.items():
        for key in ("input_path", "output_path"):
            raw_target = pathlib.Path(table[key]).expanduser()
            target = (raw_target if raw_target.is_absolute() else ROOT / raw_target).resolve()
            check(target.is_relative_to(ROOT), f"{name}.{key} stays in theme tree")

    for folder in ("generated", "fallback"):
        for name in sorted(TEMPLATES):
            text = (ROOT / folder / name).read_text()
            check("{{" not in text and "}}" not in text, f"rendered tokens resolved: {folder}/{name}")

    for folder in ("generated", "fallback"):
        parser = configparser.ConfigParser(interpolation=None)
        parser.read(ROOT / folder / "fuzzel.ini")
        check(parser.has_section("main") and parser.has_section("colors"), f"Fuzzel INI parses: {folder}")
        result = run("fuzzel", "--check-config", "--config", str(ROOT / folder / "fuzzel.ini"))
        check(result.returncode == 0, f"Fuzzel config validates: {folder}: {result.stderr.strip()}")
        tomllib.loads((ROOT / folder / "starship.toml").read_text())
        check(True, f"Starship TOML parses: {folder}")
        result = subprocess.run(
            ["starship", "print-config"],
            text=True,
            capture_output=True,
            check=False,
            env={**os.environ, "STARSHIP_CONFIG": str(ROOT / folder / "starship.toml")},
        )
        check(result.returncode == 0, f"Starship config validates: {folder}: {result.stderr.strip()}")
        result = run("fish", "-n", str(ROOT / folder / "fish-colors.fish"))
        check(result.returncode == 0, f"Fish syntax: {folder}: {result.stderr.strip()}")

    result = run("ghostty", "+validate-config", f"--config-file={ROOT / 'generated/ghostty.conf'}")
    check(result.returncode == 0, f"Ghostty config validates: {(result.stdout + result.stderr).strip()}")

    png = ROOT / "wallpapers/aurora-bloom.png"
    data = png.read_bytes()[:24]
    check(data[:8] == b"\x89PNG\r\n\x1a\n", "wallpaper is PNG")
    width, height = struct.unpack(">II", data[16:24])
    check((width, height) == (1920, 1080), "wallpaper is 1920x1080")
    check(png.stat().st_size > 250_000, "wallpaper has nontrivial image data")

    print(f"PASS: {len(expected)} required files plus syntax/config/image checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
