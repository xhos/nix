local nix = require("nix")

-- to safely pull stuff like nwg-displays
local function require_optional(name)
  local dir = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local f = io.open(dir .. "/hypr/" .. name .. ".lua", "r")

  if not f then
    return
  end

  f:close()
  require(name)
end

--------------------------------------------------------------------------
-- look and feel
--------------------------------------------------------------------------

hl.config({
  general    = {
    gaps_in     = 5,
    gaps_out    = 10,
    border_size = 1,
    layout      = "dwindle",

    col         = {
      active_border   = "rgba(262626aa)",
      inactive_border = "rgba(111111aa)",
    },

    snap        = {
      enabled        = true,
      window_gap     = 10,
      monitor_gap    = 10,
      border_overlap = true,
    },
  },

  decoration = {
    rounding         = nix.rounding,
    inactive_opacity = 1,

    shadow           = {
      enabled      = true,
      range        = 20,
      render_power = 4,
      color        = "rgba(000000b3)",
    },

    blur             = {
      size       = nix.blur.size,
      passes     = nix.blur.passes,
      special    = true,
      popups     = true,
      noise      = 0.0117,
      contrast   = 1,
      brightness = 0.4172,
      vibrancy   = 0.1696,
    },
  },

  animations = { enabled = true },

  dwindle    = { preserve_split = true },

  misc       = {
    enable_swallow           = true, -- hide windows that spawn other windows
    swallow_regex            = nix.terminal.class,
    disable_hyprland_logo    = true,
    disable_splash_rendering = true,
    focus_on_activate        = true,
    force_default_wallpaper  = 0,
    key_press_enables_dpms   = true,
    mouse_move_enables_dpms  = true,
  },

  ecosystem  = { no_update_news = true },
  cursor     = { no_hardware_cursors = true },
  xwayland   = { force_zero_scaling = true },
})

--------------------------------------------------------------------------
-- animations
--------------------------------------------------------------------------

hl.curve("quart", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "quart", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "quart" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 2, bezier = "quart" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "quart" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "quart", style = "slidevert" })

--------------------------------------------------------------------------
-- input
--------------------------------------------------------------------------

hl.config({
  input = {
    kb_layout     = "us, ru",
    kb_options    = "caps:escape,grp:alt_shift_toggle",

    accel_profile = "adaptive",
    follow_mouse  = 1,

    touchpad      = {
      disable_while_typing = true,
      natural_scroll       = true,
      scroll_factor        = 0.5,
    },
  },

  gestures = { workspace_swipe_invert = true },
})

hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })

hl.device({ name = "znt0001:00-14e5:650e-touchpad", sensitivity = 0.2 })
hl.device({ name = "razer-razer-mamba-elite-1", sensitivity = -0.3, accel_profile = "flat" })
hl.device({ name = "logitech-g305-1", sensitivity = -0.7, accel_profile = "flat" })
hl.device({ name = "dualsense-wireless-controller-touchpad", enabled = false })

--------------------------------------------------------------------------
-- the rest
--------------------------------------------------------------------------

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

require_optional("monitors")
require_optional("workspaces")

require("rules")
require("binds")

if nix.has_host_config then
  require("host")
end

--------------------------------------------------------------------------
-- autostart
--------------------------------------------------------------------------

hl.on("hyprland.start", function()
  for _, cmd in ipairs(nix.exec_once) do
    hl.exec_cmd(cmd)
  end
end)
