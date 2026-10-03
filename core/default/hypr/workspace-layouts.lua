-- Restore workspace layouts saved by archisland-hyprland-workspace-layout-toggle.

local paths = require("default.hypr.paths")
local require_all = require("default.hypr.require_all")

local layouts_dir = paths.state_home .. "/archisland/workspace-layouts"

require_all.files(layouts_dir, "archisland.workspace-layouts", { reload = true })
