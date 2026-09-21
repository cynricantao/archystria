hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 12,
        border_size = 2,
        layout      = "dwindle",

        col = {
            active_border = {
                colors = { "rgba(89b4faff)", "rgba(cba6f7ff)" },
                angle = 45,
            },
            inactive_border = "rgba(45475a99)",
        },

        resize_on_border       = true,
        extend_border_grab_area = 10,
        allow_tearing          = false,
        snap = {
            enabled     = true,
            window_gap  = 8,
            monitor_gap = 12,
            respect_gaps = true,
        },
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2.2,
        active_opacity   = 1.0,
        inactive_opacity = 0.96,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 18,
            render_power = 3,
            color         = "rgba(11111bdd)",
            color_inactive = "rgba(11111b88)",
            offset        = { 0, 5 },
            scale         = 0.97,
        },

        glow = {
            enabled        = true,
            range          = 5,
            render_power   = 2,
            color          = "rgba(89b4fa55)",
            color_inactive = "rgba(45475a22)",
        },

        blur = {
            enabled          = true,
            size             = 6,
            passes           = 3,
            new_optimizations = true,
            ignore_opacity   = true,
            xray             = false,
            noise            = 0.01,
            contrast         = 1.04,
            brightness       = 1.02,
            vibrancy         = 0.18,
            vibrancy_darkness = 0.12,
            popups           = true,
            special          = true,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_resizing = true,
        smart_split    = false,
    },

    binds = {
        scroll_event_delay = 150,
        drag_threshold     = 8,
        workspace_back_and_forth = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        focus_on_activate = true,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        vrr = 0,
    },

    cursor = {
        enable_hyprcursor = true,
        sync_gsettings_theme = true,
        hide_on_key_press = false,
    },

    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },

    opengl = {
        nvidia_anti_flicker = true,
    },
})
