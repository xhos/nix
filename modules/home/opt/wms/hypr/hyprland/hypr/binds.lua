local nix = require("nix")

local mod = "SUPER"
local modshift = mod .. " + SHIFT"
local modalt = mod .. " + ALT"
local modctrl = mod .. " + CTRL"

-- opens a TUI in its own floating terminal class (floated by rules.lua)
local function popup(app)
  return string.format(
    "uwsm-app -- %s --gtk-single-instance=false --class=%s.%s -e %s",
    nix.terminal.bin, nix.terminal.class_prefix, app, app
  )
end

local function app(cmd)
  return hl.dsp.exec_cmd("uwsm-app -- " .. cmd)
end

-- vyverne kept dwindle, everyone else moved to scrolling
local dwindle = nix.hostname == "vyverne"

--------------------------------------------------------------------------
-- compositor
--------------------------------------------------------------------------

hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + D", hl.dsp.window.float({ action = "toggle" }))
hl.bind(modshift .. " + P", hl.dsp.window.pin())

if dwindle then
  hl.bind(mod .. " + S", hl.dsp.layout("togglesplit"))
end

--------------------------------------------------------------------------
-- layout
--------------------------------------------------------------------------

if not dwindle then
  hl.bind(modshift .. " + comma", hl.dsp.layout("swapcol l"))
  hl.bind(modshift .. " + period", hl.dsp.layout("swapcol r"))

  -- colresize +/-conf wraps around at the ends; this clamps instead.
  local function column_widths()
    local out = {}
    for n in tostring(hl.get_config("scrolling.explicit_column_widths")):gmatch("[%d.]+") do
      out[#out + 1] = tonumber(n)
    end
    table.sort(out)
    return out
  end

  local function step_width(delta)
    return function()
      local win, mon = hl.get_active_window(), hl.get_active_monitor()
      if not win or not mon then return end

      local widths = column_widths()
      if #widths == 0 then return end

      -- rendered width is the column minus gaps, so snap to the nearest preset
      local frac = win.size.x / (mon.width / mon.scale)
      local idx, best = 1, math.huge
      for i, w in ipairs(widths) do
        local d = math.abs(w - frac)
        if d < best then best, idx = d, i end
      end

      hl.dispatch(hl.dsp.layout("colresize " .. widths[math.max(1, math.min(#widths, idx + delta))]))
    end
  end

  hl.bind(mod .. " + comma", step_width(-1))
  hl.bind(mod .. " + period", step_width(1))

  -- modshift + S is hyprshot, so expel goes on ALT
  hl.bind(mod .. " + S", hl.dsp.layout("consume_or_expel next"))
  hl.bind(modalt .. " + S", hl.dsp.layout("consume_or_expel prev"))

  hl.bind(mod .. " + O", hl.dsp.layout("fit expand"))
  hl.bind(modshift .. " + O", hl.dsp.layout("fit active"))

  -- scroll the tape without moving focus (steals horizontal scroll from apps)
  hl.bind(mod .. " + bracketleft", hl.dsp.layout("move -col"))
  hl.bind(mod .. " + bracketright", hl.dsp.layout("move +col"))
  hl.bind("mouse_left", hl.dsp.layout("move -col"))
  hl.bind("mouse_right", hl.dsp.layout("move +col"))
end

--------------------------------------------------------------------------
-- grouped (tabbed) windows
--------------------------------------------------------------------------

hl.bind(mod .. " + G", hl.dsp.group.toggle())

hl.bind(mod .. " + TAB", hl.dsp.group.next())
hl.bind(modshift .. " + TAB", hl.dsp.group.prev())

--------------------------------------------------------------------------
-- cycle through windows
--------------------------------------------------------------------------

hl.bind("ALT + Tab", hl.dsp.window.cycle_next({ next = true }))
hl.bind("ALT + Tab", hl.dsp.window.bring_to_top())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }))
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.bring_to_top())

--------------------------------------------------------------------------
-- move / resize windows -- arrows and hjkl
--------------------------------------------------------------------------

local directions = {
  { key = "left",  vim = "h", dir = "l", resize = { -200, 0 } },
  { key = "right", vim = "l", dir = "r", resize = { 200, 0 } },
  { key = "up",    vim = "k", dir = "u", resize = { 0, -200 } },
  { key = "down",  vim = "j", dir = "d", resize = { 0, 200 } },
}

if dwindle then
  -- SUPER + <key> moves the window, SUPER + SHIFT + <key> resizes it,
  for _, d in ipairs(directions) do
    for _, key in ipairs({ d.key, d.vim }) do
      hl.bind(mod .. " + " .. key, hl.dsp.window.move({ direction = d.dir }))

      hl.bind(modshift .. " + " .. key,
        hl.dsp.window.resize({ x = d.resize[1], y = d.resize[2], relative = true }))
    end
  end
else
  -- SUPER focuses, +SHIFT carries the window, +CTRL resizes it.

  -- horizontal focus wraps on the tape instead of jumping monitors
  local function focus_dsp(dir)
    if dir == "l" or dir == "r" then
      return hl.dsp.layout("focus " .. dir)
    end
    return hl.dsp.focus({ direction = dir })
  end

  for _, d in ipairs(directions) do
    for _, key in ipairs({ d.key, d.vim }) do
      hl.bind(mod .. " + " .. key, focus_dsp(d.dir))

      hl.bind(modshift .. " + " .. key, hl.dsp.window.move({ direction = d.dir }))

      hl.bind(modctrl .. " + " .. key,
        hl.dsp.window.resize({ x = d.resize[1], y = d.resize[2], relative = true }))
    end
  end
end

--------------------------------------------------------------------------
-- workspaces
--------------------------------------------------------------------------

-- per-monitor workspaces: real id = monitor id * 10 + n
local function monitor_workspace(n)
  local mon = hl.get_active_monitor()
  return (mon and mon.id or 0) * 10 + n
end

for i = 1, 10 do
  local key = i % 10

  hl.bind(mod .. " + " .. key, function()
    hl.dispatch(hl.dsp.focus({ workspace = monitor_workspace(i) }))
  end)

  hl.bind(modshift .. " + " .. key, function()
    hl.dispatch(hl.dsp.window.move({ workspace = monitor_workspace(i) }))
  end)
end

-- hyprland defaults monitor 2 to workspace 2, not 11 -- fix on startup
hl.on("hyprland.start", function()
  for _, mon in ipairs(hl.get_monitors()) do
    mon:set_workspace({ workspace = mon.id * 10 + 1 })
  end
end)

-- special workspace
hl.bind(mod .. " + grave", hl.dsp.workspace.toggle_special(""))
hl.bind(modshift .. " + grave", hl.dsp.window.move({ workspace = "special" }))

-- carry the active window between workspaces
for _, key in ipairs({ "up", "k" }) do
  hl.bind(modalt .. " + " .. key, hl.dsp.window.move({ workspace = "m-1" }))
end
for _, key in ipairs({ "down", "j" }) do
  hl.bind(modalt .. " + " .. key, hl.dsp.window.move({ workspace = "m+1" }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.window.move({ workspace = "e+1" }))

--------------------------------------------------------------------------
-- mouse
--------------------------------------------------------------------------

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------------------------------------------------
-- launchers and utilities
--------------------------------------------------------------------------

hl.bind(mod .. " + Q", hl.dsp.exec_cmd(nix.terminal.launch))
hl.bind(mod .. " + E", app("nautilus"))
hl.bind(mod .. " + B", app(nix.browser))
hl.bind(mod .. " + P", app("rofi-power"))
hl.bind(mod .. " + R", app("whspr"))
if dwindle then
  hl.bind(modshift .. " + L", app("hyprlock"))
else
  -- on SUPER+Escape, not SUPER+SHIFT+L: that is "move window right" now.
  hl.bind(mod .. " + Escape", app("hyprlock"))
end
hl.bind(modshift .. " + S", app("hyprshot -z -m region --clipboard-only"))
hl.bind(modshift .. " + E", app("bemoji"))

hl.bind("ALT + code:65", app("rofi -show drun -run-command 'uwsm-app -- {cmd}'"))

hl.bind(mod .. " + V", hl.dsp.exec_cmd(popup("clipse")))
hl.bind(modshift .. " + B", hl.dsp.exec_cmd(popup("bluetui")))
hl.bind(modshift .. " + N", hl.dsp.exec_cmd(popup("impala")))
hl.bind(modshift .. " + A", hl.dsp.exec_cmd(popup("wiremix")))

-- wlsunset cycles day / night / auto on SIGUSR1
hl.bind(mod .. " + F9", hl.dsp.exec_cmd("pkill -USR1 wlsunset"))

hl.bind("insert", app("volume-script --toggle-mic"))

--------------------------------------------------------------------------
-- media and brightness keys -- repeat while held, work while locked
--------------------------------------------------------------------------

local held = { repeating = true, locked = true }

hl.bind("XF86AudioRaiseVolume", app("volume-script --inc"), held)
hl.bind("XF86AudioLowerVolume", app("volume-script --dec"), held)
hl.bind("XF86AudioMute", app("volume-script --toggle"), held)
hl.bind("XF86MonBrightnessUp", app("brightness-script --inc"), held)
hl.bind("XF86MonBrightnessDown", app("brightness-script --dec"), held)
