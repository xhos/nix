local nix = require("nix")

local mod = "SUPER"
local modshift = mod .. " + SHIFT"
local modalt = mod .. " + ALT"

-- TUI helpers that open in a floating terminal of their own class
-- rules.lua floats anything matching nix.terminal.class_prefix .. ".<app>".
local function popup(app)
  return string.format(
    "uwsm-app -- %s --gtk-single-instance=false --class=%s.%s -e %s",
    nix.terminal.bin, nix.terminal.class_prefix, app, app
  )
end

local function app(cmd)
  return hl.dsp.exec_cmd("uwsm-app -- " .. cmd)
end

--------------------------------------------------------------------------
-- compositor
--------------------------------------------------------------------------

hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + D", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + S", hl.dsp.layout("togglesplit"))
hl.bind(modshift .. " + P", hl.dsp.window.pin())

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

-- SUPER + <key> moves the window, SUPER + SHIFT + <key> resizes it,
local directions = {
  { key = "left",  vim = "h", dir = "l", resize = { -200, 0 } },
  { key = "right", vim = "l", dir = "r", resize = { 200, 0 } },
  { key = "up",    vim = "k", dir = "u", resize = { 0, -200 } },
  { key = "down",  vim = "j", dir = "d", resize = { 0, 200 } },
}

for _, d in ipairs(directions) do
  for _, key in ipairs({ d.key, d.vim }) do
    hl.bind(mod .. " + " .. key, hl.dsp.window.move({ direction = d.dir }))

    hl.bind(modshift .. " + " .. key,
      hl.dsp.window.resize({ x = d.resize[1], y = d.resize[2], relative = true }))
  end
end

--------------------------------------------------------------------------
-- workspaces
--------------------------------------------------------------------------

-- SUPER + [1..9,0] focuses workspace 1..10; adding SHIFT moves the window there.
for i = 1, 10 do
  local key = i % 10
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(modshift .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

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
hl.bind(modshift .. " + L", app("hyprlock"))
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
