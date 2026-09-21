# Hyprland desktop architecture

A complete Arch + Hyprland desktop: Lua-module compositor config, top Waybar, Quickshell notifications/control center, Matugen/awww dynamic theming, greetd login, and a validated package manifest. Installable and updatable from this repository.

## Install

Requires Arch Linux. The installer writes into `~/.config` and `~/.local/share/hypr-rice`, so clone to the canonical location:

```sh
git clone git@github.com:cynricantao/hypr-rice.git ~/.local/share/hypr-rice
cd ~/.local/share/hypr-rice

# 1. Packages + root config (greetd, services). Review the plan first:
./install-packages.sh --print-plan
sudo ./install-packages.sh

# 2. Optional features (Quickshell control center, LocalSend):
./install-features-packages.sh

# 3. User config: copies sources into ~/.config, links theme fragments,
#    and backs up anything it replaces:
./install-user-files.py
systemctl --user daemon-reload
```

Log out and back in through greetd. The first session applies the bundled Aurora Bloom wallpaper and generates the theme fragments.

> Paths assume the user `cynric` at `/home/cynric` (absolute paths appear in QML/JSON configs). On a different username, replace `/home/cynric` across `source/` and `system/` before installing.

## Update

```sh
git -C ~/.local/share/hypr-rice pull
~/.local/share/hypr-rice/install-user-files.py
systemctl --user daemon-reload
```

or run `./update.sh`. The installer snapshots replaced files under `~/.local/state/hypr-rice/backups/` with a manifest, so rollback is a copy back.

## Ownership

| Responsibility | Owner | Lifecycle |
|---|---|---|
| Monitors, workspaces, windows, effects, global binds | Hyprland Lua modules | `start-hyprland` |
| Persistent top status bar | Waybar | `waybar.service` |
| Notifications and control center | Quickshell | `hypr-rice-quickshell.service` |
| Volume/media OSD | SwayOSD | `hypr-rice-swayosd.service` |
| Wallpaper transitions | awww | `hypr-rice-awww.service` |
| Palette generation and coordinated reload | Matugen + `hypr-rice-wallpaper` | one-shot wallpaper service or explicit command |
| Application launcher and utility menus | Fuzzel | on demand |
| Lock and idle policy | Hyprlock + Hypridle | on demand / `hypridle.service` |
| Clipboard history | Cliphist | `cliphist.service`, capped at 300 entries |
| Screenshots and recordings | grim/slurp + wf-recorder | on demand |
| Audio graph | PipeWire, PipeWire Pulse, WirePlumber | systemd user services |
| Portals and screen sharing | XDG portal, XDPH, GTK portal | D-Bus activated after PipeWire |
| Polkit | hyprpolkitagent | `hyprpolkitagent.service` |
| Ethernet/VPN status and LocalSend | Quickshell + NetworkManager helper | Control Center; LocalSend on demand |
| Bluetooth management | Blueman from Fuzzel | on demand; no persistent tray applet |
| Login | greetd + tuigreet | next boot, VT 1 |

`hypr-rice-session.target` is the single owner of persistent graphical-session processes. Hyprland starts it after importing the complete Wayland session environment and stops it at compositor shutdown. Portals remain D-Bus activated. Waybar remains the permanent 30-pixel top bar; one bounded Quickshell process owns the notification D-Bus service and the two top-right panels. SwayNC remains installed only as a rollback option and is not started by the session target.

## Paths

- Active Hyprland configuration: `~/.config/hypr/`
- Reviewed install sources: `~/.local/share/hypr-rice/source/`
- Theme templates and generated fragments: `~/.local/share/hypr-rice/theme/`
- User units: `~/.config/systemd/user/`
- Stable helper commands: `~/.local/bin/hypr-rice-*`
- Package manifest: `~/.local/share/hypr-rice/PACKAGES.md`
- Key reference: `~/.local/share/hypr-rice/KEYBINDS.md`

## Maintenance

Choose and apply a wallpaper:

```sh
hypr-rice-wallpaper
```

Apply a specific image:

```sh
hypr-rice-wallpaper /absolute/path/to/image.png
```

Reload generated consumers without changing wallpaper:

```sh
hypr-rice-theme-reload
```

Waybar controls:

- Volume opens the Control Center directly to audio.
- The caffeine indicator toggles idle/sleep inhibition.
- The sliders icon toggles the Control Center.
- The date/time opens notification history and marks it read; a small dot means unread notifications exist.

Panel IPC for troubleshooting:

```sh
qs ipc -c hypr-rice call panels toggleControl
qs ipc -c hypr-rice call panels openControl network
qs ipc -c hypr-rice call panels openControl localsend
qs ipc -c hypr-rice call panels toggleNotifications
qs ipc -c hypr-rice call panels closeAll
```

Run static checks:

```sh
~/.local/share/hypr-rice/validate-configs.py
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

Reinstall user files from reviewed sources:

```sh
~/.local/share/hypr-rice/install-user-files.py
systemctl --user daemon-reload
```

The installer creates a timestamped backup and manifest under `~/.local/state/hypr-rice/backups/` before replacing managed targets.

## Recovery and rollback

Switch to another TTY with `Ctrl+Alt+F2`, log in, and inspect:

```sh
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
systemctl --user --failed
journalctl --user -b
```

Initial user backup:

```text
~/.local/state/hypr-rice/backups/20260919-210651
```

Root backups include timestamped `/etc/greetd/config.toml.pre-hypr-rice-*` and `/etc/pam.d/greetd.pre-hypr-rice-*` files. To restore a console-first boot:

```sh
sudo systemctl set-default multi-user.target
sudo systemctl disable greetd.service
```

## Live acceptance results

- Hyprland parsed and launched successfully on `HDMI-A-1` at 1920×1080 and 120.003 Hz.
- Waybar remained at the top, reserved 30 pixels, and used compositor-protocol workspace activation; workspace 1↔2 clicks were exercised.
- All 93 live Hyprland binds carried descriptions.
- Fuzzel, the grouped live keybinding viewer, Ghostty/Fish/Starship, Quickshell notifications/Control Center, SwayOSD, floating mode, Hyprlock, screenshot, recording, wallpaper, Nautilus, trash, and archive association were exercised.
- `Print`, `Ctrl+Print`, and `Alt+Print` capture paths saved PNGs, copied them to the clipboard, and emitted desktop notifications.
- PipeWire screen sharing was verified through an OBS monitor preview.
- No user systemd units were failed after validation.

A cold-boot greetd login and removable-storage mount cannot be validated without rebooting or attaching removable storage; the configured files and service enablement were read back successfully.
