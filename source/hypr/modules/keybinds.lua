local mod = "SUPER"
local terminal = "ghostty"
local file_manager = "nautilus --new-window"
local browser = "firefox"
local helper = "/home/cynric/.local/bin/"

local function bind(keys, dispatcher, description, options)
    options = options or {}
    options.description = description
    hl.bind(keys, dispatcher, options)
end

-- Universal recovery access remains available through shortcut inhibition and submaps.
local emergency = {
    submap_universal = true,
    dont_inhibit = true,
    allow_input_capture = true,
}
bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal), "Emergency: open terminal", emergency)
bind(mod .. " + SHIFT + ESCAPE", hl.dsp.exit(), "Emergency: exit Hyprland", emergency)

-- Applications and desktop surfaces.
bind(mod .. " + SUPER_L", hl.dsp.exec_cmd("fuzzel"), "Open application launcher", { release = true })
bind(mod .. " + E", hl.dsp.exec_cmd(file_manager), "Open file manager")
bind(mod .. " + B", hl.dsp.exec_cmd(browser), "Open web browser")
bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"), "Lock the session")
bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client --toggle-panel --skip-wait"), "Toggle notification center")
bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client --toggle-dnd --skip-wait"), "Toggle do-not-disturb")
bind(mod .. " + V", hl.dsp.exec_cmd(helper .. "hypr-rice-clipboard"), "Open clipboard history")
bind(mod .. " + CTRL + V", hl.dsp.exec_cmd(helper .. "hypr-rice-clipboard-clear"), "Clear clipboard history with confirmation")
bind(mod .. " + C", hl.dsp.exec_cmd(helper .. "hypr-rice-calculator"), "Open calculator")
bind(mod .. " + R", hl.dsp.exec_cmd(helper .. "hypr-rice-command"), "Open command runner")
bind(mod .. " + SHIFT + F", hl.dsp.exec_cmd(helper .. "hypr-rice-file-search"), "Search files")
bind(mod .. " + W", hl.dsp.exec_cmd(helper .. "hypr-rice-web-search"), "Search the web")
bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(helper .. "hypr-rice-wallpaper"), "Choose wallpaper and regenerate theme")
bind(mod .. " + ESCAPE", hl.dsp.exec_cmd(helper .. "hypr-rice-power-menu"), "Open confirmed power menu")
bind(mod .. " + SLASH", hl.dsp.exec_cmd(helper .. "hypr-rice-keybinds"), "Show keybinding reference")
bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd(helper .. "hypr-rice-theme-reload"), "Reload generated theme")

-- Window state.
bind(mod .. " + Q", hl.dsp.window.close(), "Close focused window")
bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "Toggle fullscreen")
bind(mod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), "Toggle maximize")
bind(mod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind(mod .. " + P", hl.dsp.window.pseudo({ action = "toggle" }), "Toggle pseudotiling")
bind(mod .. " + G", hl.dsp.group.toggle(), "Toggle window group")
bind(mod .. " + TAB", hl.dsp.window.cycle_next({ next = true }), "Focus next window")
bind(mod .. " + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }), "Focus previous window")
bind(mod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"), "Toggle scratchpad")
bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }), "Move window to scratchpad")

-- Directional focus and movement.
for _, entry in ipairs({
    { "LEFT", "l", "left" }, { "RIGHT", "r", "right" },
    { "UP", "u", "up" }, { "DOWN", "d", "down" },
    { "H", "l", "left" }, { "J", "d", "down" },
    { "K", "u", "up" }, { "SEMICOLON", "r", "right" },
}) do
    bind(mod .. " + " .. entry[1], hl.dsp.focus({ direction = entry[2] }), "Focus window " .. entry[3], { repeating = true })
    bind(mod .. " + SHIFT + " .. entry[1], hl.dsp.window.move({ direction = entry[2] }), "Move window " .. entry[3], { repeating = true })
end

-- Workspaces 1-10 (key 0 selects workspace 10).
for workspace = 1, 10 do
    local key = workspace % 10
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }), "Switch to workspace " .. workspace)
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }), "Move window to workspace " .. workspace)
end
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Switch to next existing workspace")
bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "Switch to previous existing workspace")

-- Mouse move/resize.
bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Drag focused window", { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize focused window", { mouse = true })

-- Screenshots: reliable Wayland-native capture, save, clipboard, and notification.
bind("PRINT", hl.dsp.exec_cmd(helper .. "hypr-rice-screenshot region"), "Capture selected region")
bind("CTRL + PRINT", hl.dsp.exec_cmd(helper .. "hypr-rice-screenshot full"), "Capture all outputs")
bind("ALT + PRINT", hl.dsp.exec_cmd(helper .. "hypr-rice-screenshot active"), "Capture focused window")

-- Recording stays available without occupying the requested screenshot chords.
bind(mod .. " + CTRL + PRINT", hl.dsp.exec_cmd(helper .. "hypr-rice-recording toggle region"), "Toggle region recording")
bind(mod .. " + CTRL + SHIFT + PRINT", hl.dsp.exec_cmd(helper .. "hypr-rice-recording toggle full"), "Toggle full-output recording")
bind(mod .. " + ALT + PRINT", hl.dsp.exec_cmd(helper .. "hypr-rice-recording toggle active"), "Toggle focused-window recording")

-- Audio and media. SwayOSD owns both the action and visual feedback.
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), "Raise output volume", { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), "Lower output volume", { locked = true, repeating = true })
bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), "Toggle output mute", { locked = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), "Toggle microphone mute", { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), "Play or pause media", { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), "Play or pause media", { locked = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"), "Play next track", { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl prev"), "Play previous track", { locked = true })

-- Resize mode; emergency binds remain universal inside this submap.
bind(mod .. " + CTRL + R", hl.dsp.submap("resize"), "Enter resize mode")
hl.define_submap("resize", function()
    for _, entry in ipairs({
        { "LEFT", -30, 0, "left" }, { "RIGHT", 30, 0, "right" },
        { "UP", 0, -30, "up" }, { "DOWN", 0, 30, "down" },
        { "H", -30, 0, "left" }, { "SEMICOLON", 30, 0, "right" },
        { "K", 0, -30, "up" }, { "J", 0, 30, "down" },
    }) do
        bind(entry[1], hl.dsp.window.resize({ x = entry[2], y = entry[3], relative = true }), "Resize window " .. entry[4], { repeating = true })
    end
    bind("ESCAPE", hl.dsp.submap("reset"), "Exit resize mode")
    bind("RETURN", hl.dsp.submap("reset"), "Exit resize mode")
end)
