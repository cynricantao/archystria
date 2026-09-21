#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

git pull --ff-only
./install-user-files.py
systemctl --user daemon-reload

echo "Updated. Log out and back in (or restart the session target) to apply."
