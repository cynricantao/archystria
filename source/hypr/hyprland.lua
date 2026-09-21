-- Hyprland 0.56 Lua configuration entry point.
-- Draft only: install as ~/.config/hypr/hyprland.lua together with modules/.

require("modules.monitors")
require("modules.environment")
require("modules.input")
require("modules.appearance")
-- Matugen-generated colors override only palette fields; fallback colors above remain safe.
pcall(require, "modules.generated_colors")
require("modules.animations")
require("modules.keybinds")
require("modules.window_rules")
require("modules.autostart")
