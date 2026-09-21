-- systemd owns persistent session processes; Hyprland only brackets the session target.
hl.on("hyprland.start", function()
    hl.exec_cmd([[dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE XDG_SESSION_CLASS QT_QPA_PLATFORMTHEME && systemctl --user import-environment WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE XDG_SESSION_CLASS QT_QPA_PLATFORMTHEME && systemctl --user start hypr-rice-session.target]])
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("systemctl --user stop hypr-rice-session.target graphical-session.target")
end)
