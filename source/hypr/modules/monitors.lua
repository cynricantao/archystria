-- Display layout: HKC 1080p panel over HDMI at its native 120 Hz mode.
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@120.003",
    position = "0x0",
    scale    = 1,
    bitdepth = 8,
    vrr      = 0,
})

-- Safe hot-plug fallback for any additional output.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto-right",
    scale    = 1,
})

-- Keep the primary workspaces on the known display.
for workspace = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(workspace),
        monitor   = "HDMI-A-1",
        persistent = workspace == 1,
        default    = workspace == 1,
    })
end
