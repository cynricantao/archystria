#!/usr/bin/env bash
set -euo pipefail

packages=(
  hyprland waybar hyprlock hypridle
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  polkit hyprpolkitagent greetd greetd-tuigreet
  pipewire-audio pipewire-alsa pipewire-pulse wireplumber
  bluez bluez-utils
  matugen awww
  inter-font ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
  ttf-material-symbols-variable otf-font-awesome
  papirus-icon-theme capitaine-cursors adw-gtk-theme nwg-look
  ghostty ghostty-nautilus fish starship firefox fuzzel swaync swayosd
  nautilus sushi file-roller gvfs gvfs-mtp gvfs-smb udisks2 ntfs-3g
  ffmpegthumbnailer wl-clipboard cliphist grim slurp swappy libnotify
  jq fd libqalculate xdg-user-dirs xdg-utils wev seahorse
  playerctl pavucontrol wf-recorder obs-studio libva-nvidia-driver egl-wayland
  network-manager-applet blueman gnome-keyring libsecret
  qt5-wayland qt6-wayland qt5ct qt6ct
)

if [[ ${1:-} == --print-plan ]]; then
  pacman -Sp --print-format '%r/%n %v %s' --needed "${packages[@]}"
  exit 0
fi

if [[ ${EUID} -ne 0 ]]; then
  printf 'Run this script with sudo.\n' >&2
  exit 1
fi

printf 'Installing %d explicitly requested packages from official Arch repositories.\n' "${#packages[@]}"
pacman -Syu --needed "${packages[@]}"

python /home/cynric/.local/share/hypr-rice/system/configure-root.py

systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable greetd.service

printf '\nPackage installation and root-owned configuration completed.\n'
printf 'greetd is enabled for the next boot but was not started, so this TTY remains intact.\n'
