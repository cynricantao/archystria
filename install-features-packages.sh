#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  printf '%s\n' 'Run this script as your normal user; it invokes sudo only for pacman.' >&2
  exit 1
fi

# Keep Arch coherent: install Quickshell through a full repository upgrade.
sudo pacman -Syu --needed quickshell

# LocalSend is not in the official repositories. localsend-bin 1.18.2-1 wraps
# the signed upstream release and declares the fixed runtime dependencies shown
# by `yay -Si localsend-bin`. Keep yay's normal PKGBUILD/diff confirmation.
yay -S --needed localsend-bin
