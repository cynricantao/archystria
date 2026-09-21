#!/usr/bin/env python3
"""Regression checks for bounded Quickshell panel geometry."""
from pathlib import Path
import unittest

HOME = Path.home()
QML = HOME / ".config/quickshell/hypr-rice"
HYPR_RULES = HOME / ".config/hypr/modules/window_rules.lua"


class ControlCenterLayoutTests(unittest.TestCase):
    def test_active_section_claims_scroll_view_width(self) -> None:
        text = (QML / "ControlCenter.qml").read_text()
        self.assertIn("id: controlScroll", text)
        self.assertIn("contentWidth: availableWidth", text)
        self.assertIn("width: controlScroll.availableWidth", text)

    def test_control_center_sizes_to_visible_content(self) -> None:
        text = (QML / "ControlCenter.qml").read_text()
        self.assertIn("implicitHeight: Math.min(820, panelContent.implicitHeight + 32)", text)
        self.assertIn("Layout.preferredHeight: Math.min(controlContent.implicitHeight, 650)", text)

    def test_control_center_has_no_duplicate_session_actions(self) -> None:
        text = (QML / "ControlCenter.qml").read_text()
        self.assertEqual(text.count("session-action"), 1)
        for duplicate in ("sessionAction", 'text: "Lock"', 'text: "Suspend"', 'text: "Logout"', 'text: "Restart"', 'text: "Power"'):
            self.assertNotIn(duplicate, text)


class NotificationCenterLayoutTests(unittest.TestCase):
    def test_center_is_bounded_and_has_no_panel_background(self) -> None:
        text = (QML / "NotificationCenter.qml").read_text()
        self.assertNotIn("anchors.bottom: true", text)
        self.assertIn("implicitWidth: 390", text)
        self.assertIn("implicitHeight: Math.min(700, centerContent.implicitHeight + 28)", text)
        self.assertIn("PanelSurface {\n            id: surface", text)
        self.assertNotIn("color: Theme.bg", text)

    def test_notification_content_claims_available_width(self) -> None:
        text = (QML / "NotificationCenter.qml").read_text()
        self.assertIn("id: notificationScroll", text)
        self.assertIn("contentWidth: availableWidth", text)
        self.assertIn("width: notificationScroll.availableWidth", text)

    def test_opening_center_removes_overlapping_popup_cards(self) -> None:
        text = (QML / "NotificationCenter.qml").read_text()
        self.assertIn("for (const key of root.store.popupKeys.slice())", text)
        self.assertIn("root.store.removePopup(key);", text)

    def test_center_uses_cards_without_app_header_rectangles(self) -> None:
        center = (QML / "NotificationCenter.qml").read_text()
        card = (QML / "NotificationCard.qml").read_text()
        self.assertNotIn("color: Theme.panel", center)
        self.assertIn("compact: true", center)
        self.assertIn("groupCount:", center)
        self.assertIn("property bool compact: false", card)
        self.assertIn("property int groupCount: 1", card)
        self.assertIn("Qt.rgba", card)

    def test_quickshell_cards_receive_compositor_blur(self) -> None:
        text = HYPR_RULES.read_text()
        self.assertIn('name  = "blur-quickshell"', text)
        self.assertIn('match = { namespace = "^quickshell$" }', text)
        self.assertIn("ignore_alpha = 0.15", text)


if __name__ == "__main__":
    unittest.main()
