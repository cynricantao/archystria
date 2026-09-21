#!/usr/bin/env python3
"""Apply the small root-owned part of the desktop setup."""

from __future__ import annotations

import os
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

invoker = os.environ.get("SUDO_USER")
if not invoker:
    raise SystemExit("run via sudo so SUDO_USER identifies the target user")
SOURCE = Path("/home") / invoker / ".local/share/hypr-rice/system/greetd-config.toml"
TARGET = Path('/etc/greetd/config.toml')
PAM = Path('/etc/pam.d/greetd')
STAMP = datetime.now().strftime('%Y%m%d-%H%M%S')


def backup(path: Path) -> None:
    if path.exists():
        shutil.copy2(path, path.with_name(f'{path.name}.pre-hypr-rice-{STAMP}'))


def configure_greetd() -> None:
    if not SOURCE.exists():
        raise SystemExit(f'missing source file: {SOURCE}')
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    backup(TARGET)
    shutil.copy2(SOURCE, TARGET)
    TARGET.chmod(0o644)


def configure_keyring_pam() -> None:
    if not PAM.exists():
        raise SystemExit(f'missing PAM file after installing greetd: {PAM}')
    text = PAM.read_text()
    auth_line = 'auth       optional     pam_gnome_keyring.so'
    session_line = 'session    optional     pam_gnome_keyring.so auto_start'
    if 'pam_gnome_keyring.so' in text:
        return

    backup(PAM)
    lines = text.rstrip().splitlines()
    auth_positions = [i for i, line in enumerate(lines) if line.lstrip().startswith('auth ')]
    insert_at = auth_positions[-1] + 1 if auth_positions else 1
    lines.insert(insert_at, auth_line)
    session_positions = [i for i, line in enumerate(lines) if line.lstrip().startswith('session ')]
    insert_at = session_positions[-1] + 1 if session_positions else len(lines)
    lines.insert(insert_at, session_line)
    PAM.write_text('\n'.join(lines) + '\n')


def configure_login_target() -> None:
    # Enable only; do not start greetd while the current tty1 TUI is active.
    subprocess.run(['systemctl', 'enable', 'greetd.service'], check=True)
    subprocess.run(['systemctl', 'set-default', 'graphical.target'], check=True)


if __name__ == '__main__':
    configure_greetd()
    configure_keyring_pam()
    configure_login_target()
    print(f'Configured {TARGET} and {PAM}; timestamp: {STAMP}')
