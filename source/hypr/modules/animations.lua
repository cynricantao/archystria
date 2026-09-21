hl.config({
    animations = {
        enabled = true,
        workspace_wraparound = false,
    },
})

-- Fast, critically damped motion with short fades for a 120 Hz desktop.
hl.curve("riceFastOut", {
    type = "bezier",
    points = { { 0.22, 1.0 }, { 0.36, 1.0 } },
})
hl.curve("riceFastIn", {
    type = "bezier",
    points = { { 0.40, 0.0 }, { 1.0, 1.0 } },
})
hl.curve("riceLinear", {
    type = "bezier",
    points = { { 0.0, 0.0 }, { 1.0, 1.0 } },
})
hl.curve("riceSpring", {
    type = "spring",
    mass = 1.0,
    stiffness = 420.0,
    dampening = 36.0,
})

hl.animation({ leaf = "global",        enabled = true, speed = 2.2, bezier = "riceFastOut" })
hl.animation({ leaf = "windows",       enabled = true, speed = 2.2, spring = "riceSpring" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 2.0, spring = "riceSpring", style = "popin 92%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.4, bezier = "riceFastIn", style = "popin 94%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 1.8, spring = "riceSpring" })
hl.animation({ leaf = "fade",          enabled = true, speed = 1.6, bezier = "riceFastOut" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.5, bezier = "riceFastOut" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.2, bezier = "riceFastIn" })
hl.animation({ leaf = "border",        enabled = true, speed = 1.6, bezier = "riceFastOut" })
hl.animation({ leaf = "layers",        enabled = true, speed = 1.8, bezier = "riceFastOut", style = "fade" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 1.7, bezier = "riceFastOut", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.2, bezier = "riceFastIn", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.5, bezier = "riceFastOut" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.2, bezier = "riceFastIn" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.1, bezier = "riceFastOut", style = "slidefade 18%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 1.9, spring = "riceSpring", style = "slidefade 14%" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 2.0, bezier = "riceFastOut" })
