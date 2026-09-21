# Keybindings

`SUPER` means the Windows/Super key. Every live bind has a Hyprland description and appears in the Waybar keybind helper.

## Launcher and utilities

| Keys | Action |
|---|---|
| `SUPER` (tap) | Application launcher |
| `SUPER+Return` | Ghostty terminal; emergency recovery bind |
| `SUPER+E` | Nautilus file manager |
| `SUPER+B` | Firefox |
| `SUPER+V` | Clipboard history |
| `SUPER+Ctrl+V` | Confirm and clear clipboard history |
| `SUPER+C` | Calculator |
| `SUPER+R` | Command runner |
| `SUPER+Shift+F` | File search |
| `SUPER+W` | Web search |
| `SUPER+Shift+W` | Wallpaper chooser and theme regeneration |
| `SUPER+/` | Keybinding reference |
| `SUPER+Shift+R` | Reload generated theme consumers |
| `SUPER+Escape` | Confirmed session/power menu |

## Windows and workspaces

| Keys | Action |
|---|---|
| `SUPER+Q` | Close focused window |
| `SUPER+F` | Toggle fullscreen |
| `SUPER+Ctrl+F` | Toggle maximize |
| `SUPER+Space` | Toggle floating |
| `SUPER+P` | Toggle pseudotiling |
| `SUPER+G` | Toggle window group |
| `SUPER+Tab` | Focus next window |
| `SUPER+Shift+Tab` | Focus previous window |
| `SUPER+Arrow` | Move focus |
| `SUPER+Shift+Arrow` | Move window |
| `SUPER+Ctrl+Arrow` | Resize window |
| `SUPER+1…0` | Switch to workspace 1…10 |
| `SUPER+Shift+1…0` | Move focused window to workspace 1…10 |
| `SUPER+mouse wheel` | Cycle workspaces |
| `SUPER+S` | Toggle scratchpad |
| `SUPER+Shift+S` | Move window to scratchpad |
| `SUPER+left drag` | Move floating/tiled window |
| `SUPER+right drag` | Resize window |

## Desktop surfaces

| Keys | Action |
|---|---|
| `SUPER+N` | Toggle SwayNC control center |
| `SUPER+Shift+N` | Toggle Do Not Disturb |
| `SUPER+L` | Lock with Hyprlock |
| `SUPER+Shift+Escape` | Exit Hyprland; emergency recovery bind |

## Capture

| Keys | Action |
|---|---|
| `Print` | Region screenshot, save and copy |
| `Ctrl+Print` | Full-output screenshot, save and copy |
| `Alt+Print` | Active-window screenshot, save and copy |
| `SUPER+Ctrl+Print` | Start/stop region recording |
| `SUPER+Ctrl+Shift+Print` | Start/stop full-output recording |
| `SUPER+Alt+Print` | Start/stop active-window recording |

Screenshots are stored under `~/Pictures/Screenshots` as `Screenshot-YYYY-MM-DD-HH-MM-SS.png`; recordings are stored under `~/Videos/Screencasts`.

## Media

The keyboard volume, mute, microphone-mute, and media keys route through SwayOSD/playerctl and show OSD feedback. Waybar audio supports click-to-open `pavucontrol` and scroll-to-adjust volume.
