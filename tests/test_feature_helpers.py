#!/usr/bin/env python3
"""Behavior tests for backend helper drafts."""

from __future__ import annotations

import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1] / "source/bin"
PANEL = ROOT / "hypr-rice-panel-data"
CAFFEINATE = ROOT / "hypr-rice-caffeinate"
PAVUCONTROL = ROOT / "hypr-rice-pavucontrol"
CLOCK = ROOT / "hypr-rice-waybar-clock"


def make_executable(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


class BackendHelperTests(unittest.TestCase):
    def test_panel_help_documents_commands(self) -> None:
        result = subprocess.run(
            [str(PANEL), "--help"], text=True, capture_output=True, timeout=3
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("network", result.stdout)
        self.assertIn("vpn", result.stdout)
        self.assertIn("localsend", result.stdout)
        self.assertIn("stream", result.stdout)

    def test_panel_stream_emits_composite_json(self) -> None:
        process = subprocess.Popen(
            [str(PANEL), "stream", "--interval", "1"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        try:
            assert process.stdout is not None
            payload = json.loads(process.stdout.readline())
        finally:
            process.terminate()
            process.wait(timeout=3)
            if process.stdout is not None:
                process.stdout.close()
            if process.stderr is not None:
                process.stderr.close()
        self.assertIn("network", payload)
        self.assertIn("localsend", payload)

    def test_network_reports_only_active_ethernet_and_vpns(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            bindir = Path(tmp)
            make_executable(
                bindir / "nmcli",
                """#!/usr/bin/env python3
import sys
args = sys.argv[1:]
if args[-2:] == ['device', 'status']:
    print('wlp2s0:wifi:connected:Home WiFi')
    print('eno1:ethernet:connected:Wired\\: office')
    print('enp9s0:ethernet:disconnected:')
elif args[-3:] == ['device', 'show', 'eno1']:
    print('IP4.ADDRESS[1]:192.168.1.246/24')
    print('IP4.GATEWAY:192.168.1.1')
    print('IP4.DNS[1]:192.168.1.1')
    print('IP4.DNS[2]:9.9.9.9')
    print('IP6.ADDRESS[1]:fe80\\::1234/64')
elif args[-2:] == ['connection', 'show']:
    print('Work VPN:vpn::deactivated')
    print('Wireguard:wireguard:wg0:activated')
    print('Wired connection 1:802-3-ethernet:eno1:activated')
else:
    raise SystemExit('unexpected nmcli arguments: ' + repr(args))
""",
            )
            env = os.environ | {"PATH": f"{bindir}:/usr/bin"}
            result = subprocess.run(
                [str(PANEL), "network"], env=env, text=True,
                capture_output=True, timeout=3,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["interface"], "eno1")
        self.assertEqual(payload["connection"], "Wired: office")
        self.assertEqual(payload["ipv4"], "192.168.1.246")
        self.assertEqual(payload["ipv6"], "fe80::1234")
        self.assertEqual(payload["gateway"], "192.168.1.1")
        self.assertEqual(payload["dns"], ["192.168.1.1", "9.9.9.9"])
        self.assertEqual(
            payload["vpns"],
            [
                {"name": "Wireguard", "state": "activated", "active": True},
                {"name": "Work VPN", "state": "deactivated", "active": False},
            ],
        )

    def test_vpn_invokes_nmcli_without_a_shell_or_leaking_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            bindir = Path(tmp)
            log = bindir / "args.json"
            make_executable(
                bindir / "nmcli",
                """#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
if args[-2:] == ['connection', 'show']:
    print('Work VPN:vpn::deactivated')
else:
    with open(os.environ['ARGS_LOG'], 'w', encoding='utf-8') as handle:
        json.dump(args, handle)
    print('password=must-not-leak')
""",
            )
            env = os.environ | {
                "PATH": f"{bindir}:/usr/bin",
                "ARGS_LOG": str(log),
            }
            result = subprocess.run(
                [str(PANEL), "vpn", "up", "Work VPN"], env=env, text=True,
                capture_output=True, timeout=3,
            )
            called = json.loads(log.read_text(encoding="utf-8"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("password", result.stdout)
        self.assertEqual(json.loads(result.stdout), {"name": "Work VPN", "state": "up"})
        self.assertEqual(
            called,
            ["--wait", "10", "--colors", "no", "connection", "up", "id", "Work VPN"],
        )

    def test_vpn_rejects_control_characters(self) -> None:
        result = subprocess.run(
            [str(PANEL), "vpn", "up", "bad\nname"], text=True,
            capture_output=True, timeout=3,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("invalid VPN profile name", json.loads(result.stdout)["error"])

    def test_localsend_reports_persisted_alias_and_routed_ip(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            prefs = home / ".local/share/org.localsend.localsend_app/shared_preferences.json"
            prefs.parent.mkdir(parents=True)
            prefs.write_text(
                json.dumps({"flutter.ls_alias": "Quiet Fox", "flutter.ls_port": 9}),
                encoding="utf-8",
            )
            bindir = Path(tmp) / "bin"
            bindir.mkdir()
            make_executable(
                bindir / "ip",
                """#!/usr/bin/env python3
print('[{"prefsrc":"10.23.4.5","dev":"eno1"}]')
""",
            )
            env = os.environ | {
                "HOME": str(home),
                "XDG_DATA_HOME": str(home / ".local/share"),
                "PATH": f"{bindir}:/usr/bin",
            }
            result = subprocess.run(
                [str(PANEL), "localsend"], env=env, text=True,
                capture_output=True, timeout=3,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["alias"], "Quiet Fox")
        self.assertEqual(payload["alias_source"], "persisted")
        self.assertEqual(payload["ip"], "10.23.4.5")
        # Process state is machine-global and may already be active while this
        # isolated HOME verifies persisted metadata parsing.
        self.assertIsInstance(payload["process_running"], bool)
        self.assertIsInstance(payload["ready"], bool)

    def test_caffeinate_status_is_waybar_json(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            bindir = Path(tmp)
            make_executable(
                bindir / "systemctl",
                """#!/usr/bin/env python3
import sys
if sys.argv[1:] == ['--user', 'is-active', 'hypr-rice-caffeinate.service']:
    print('active')
else:
    raise SystemExit(2)
""",
            )
            env = os.environ | {"PATH": f"{bindir}:/usr/bin"}
            result = subprocess.run(
                [str(CAFFEINATE), "status"], env=env, text=True,
                capture_output=True, timeout=3,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["class"], "active")
        self.assertEqual(payload["alt"], "on")

    def test_pavucontrol_wrapper_scopes_dark_theme_and_preserves_arguments(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            bindir = Path(tmp)
            output = bindir / "result.json"
            make_executable(
                bindir / "pavucontrol",
                """#!/usr/bin/env python3
import json, os, sys
with open(os.environ['RESULT'], 'w', encoding='utf-8') as handle:
    json.dump({'theme': os.environ.get('GTK_THEME'), 'args': sys.argv[1:]}, handle)
""",
            )
            env = os.environ | {
                "PATH": f"{bindir}:/usr/bin",
                "RESULT": str(output),
                "GTK_THEME": "SomethingElse",
            }
            result = subprocess.run(
                [str(PAVUCONTROL), "--tab", "3"], env=env, text=True,
                capture_output=True, timeout=3,
            )
            recorded = json.loads(output.read_text(encoding="utf-8"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(recorded, {"theme": "adw-gtk3-dark:dark", "args": ["--tab", "3"]})

    def test_waybar_clock_reflects_unread_state(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            runtime = Path(tmp)
            (runtime / "hypr-rice-notifications.json").write_text(
                json.dumps({"unread": 2}), encoding="utf-8"
            )
            result = subprocess.run(
                [str(CLOCK), "--once"],
                env=os.environ | {"XDG_RUNTIME_DIR": str(runtime)},
                text=True, capture_output=True, timeout=3,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["class"], "unread")
        self.assertIn("●", payload["text"])


if __name__ == "__main__":
    unittest.main()
