# Aurora Bloom dynamic theme

This directory is the canonical Matugen/awww theme tree used by the installed desktop.

## Apply a wallpaper

```sh
hypr-rice-wallpaper
hypr-rice-wallpaper /path/to/image.jpg
```

The command applies the image through `awww`, records it for the next login, renders every Matugen consumer fragment under `generated/`, and reloads the affected components. Generated files are outputs; edit files under `templates/` instead.

The included original wallpaper is `wallpapers/aurora-bloom.png`. If Matugen fails, `scripts/wallpaper.sh` restores the known-good fragments under `fallback/`.

## Consumers

- Waybar, SwayNC (rollback only), SwayOSD, and GTK import generated CSS.
- Quickshell uses `generated/quickshell-theme.qml` through the active `Theme.qml` symlink.
- Fuzzel uses `generated/fuzzel.ini`.
- Ghostty includes `generated/ghostty.conf`.
- Hyprland loads `generated/hyprland-colors.lua` through a safe optional module.
- Hyprlock sources `generated/hyprlock.conf`.
- Fish sources `generated/fish-colors.fish`.
- Starship reads `generated/starship.toml`.

## Other helpers

```sh
hypr-rice-clipboard
hypr-rice-calculator
hypr-rice-command
hypr-rice-file-search
hypr-rice-web-search
hypr-rice-keybinds
hypr-rice-power-menu
hypr-rice-theme-reload
```

Power actions require explicit confirmation. Helper scripts avoid `eval` and pass selections as quoted arguments.

## Validate

```sh
python3 tests/verify.py
```
