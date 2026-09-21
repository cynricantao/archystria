-- Ignore client maximize requests so layout decisions remain compositor-owned.
hl.window_rule({
    name  = "suppress-client-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- XWayland override-redirect windows can otherwise steal focus while dragging.
hl.window_rule({
    name = "fix-xwayland-drag-focus",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Utility and authentication windows should be transient and centered.
hl.window_rule({
    name  = "float-desktop-utilities",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor)$" },
    float = true,
    center = true,
    size = { 900, 620 },
})
hl.window_rule({
    name  = "focus-pinentry",
    match = { class = "^(pinentry-)(.*)$" },
    float = true,
    center = true,
    stay_focused = true,
})

-- Browser picture-in-picture stays visible without dominating the layout.
hl.window_rule({
    name  = "picture-in-picture",
    match = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    size = { 640, 360 },
})

-- Fullscreen media and games inhibit idle only while actually fullscreen.
hl.window_rule({
    name  = "fullscreen-idle-inhibit",
    match = { fullscreen = true },
    idle_inhibit = "fullscreen",
})

-- Keep the top bar, launcher, and notification surfaces crisp over blur.
hl.layer_rule({
    name  = "blur-waybar",
    match = { namespace = "^(waybar|main)$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.20,
})
hl.layer_rule({
    name  = "blur-launcher",
    match = { namespace = "^fuzzel$" },
    blur = true,
    ignore_alpha = 0.15,
    dim_around = true,
})
hl.layer_rule({
    name  = "blur-swaync",
    match = { namespace = "^swaync-(notification-window|control-center)$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.15,
})
hl.layer_rule({
    name  = "blur-quickshell",
    match = { namespace = "^quickshell$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.15,
})
hl.layer_rule({
    name  = "instant-region-selection",
    match = { namespace = "^selection$" },
    no_anim = true,
})
