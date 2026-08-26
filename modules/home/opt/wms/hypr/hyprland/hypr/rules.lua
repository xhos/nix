local nix = require("nix")

--------------------------------------------------------------------------
-- layer rules
--------------------------------------------------------------------------

-- Shells that should get blur but nothing else.
for _, ns in ipairs({ "RegularWindow", "PopupWindow", "wvkbd", "gtk-layer-shell" }) do
  hl.layer_rule({ match = { namespace = "^(" .. ns .. ")$" }, blur = true })
end

-- Blur plus a fully transparent base so the blur actually shows through.
for _, ns in ipairs({ "notifications", "rofi" }) do
  hl.layer_rule({
    match        = { namespace = "^(" .. ns .. ")$" },
    blur         = true,
    ignore_alpha = 0.0,
  })
end

hl.layer_rule({
  match        = { namespace = "^(waybar)$" },
  blur         = true,
  ignore_alpha = 0.0,
  blur_popups  = true,
})

--------------------------------------------------------------------------
-- window rules
--------------------------------------------------------------------------

-- xwaylandvideobridge must exist but never be seen.
hl.window_rule({
  match            = { class = "^(xwaylandvideobridge)$" },
  opacity          = "0.0 override",
  no_anim          = true,
  no_initial_focus = true,
  max_size         = "1 1",
  no_blur          = true,
})

-- dim the rest of the screen behind auth prompts
for _, class in ipairs({
  "gcr-prompter",
  "xdg-desktop-portal-gtk",
  "polkit-gnome-authentication-agent-1",
}) do
  hl.window_rule({ match = { class = "^(" .. class .. ")$" }, dim_around = true })
end

-- TUI popups launched by binds.lua, plus the GUI tools they replaced
local popup_class = string.format(
  "^(%s\\.(clipse|bluetui|impala|wiremix))$",
  (nix.terminal.class_prefix:gsub("%.", "\\."))
)

hl.window_rule({ match = { class = popup_class }, float = true, size = "622 652" })

for _, class in ipairs({
  "pavucontrol",
  "blueman-manager",
  "clipse",
  "bluetui",
  "impala",
  "wiremix",
}) do
  hl.window_rule({
    match = { class = "^(" .. class .. ")$" },
    float = true,
    size  = "622 652",
  })
end

hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true })

hl.window_rule({ match = { title = "^(Media viewer)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })

-- make web apps tile properly
hl.window_rule({ match = { class = "web-app" }, tile = true })

--------------------------------------------------------------------------
-- idle inhibit
--------------------------------------------------------------------------

hl.window_rule({ match = { class = "^(mpv|.+exe|celluloid)$" }, idle_inhibit = "focus" })
hl.window_rule({
  match        = { class = "^(firefox)$", title = "^(.*YouTube.*)$" },
  idle_inhibit = "focus",
})
hl.window_rule({ match = { class = "^(firefox)$" }, idle_inhibit = "fullscreen" })

--------------------------------------------------------------------------
-- obsidian transparency
--------------------------------------------------------------------------

hl.window_rule({
  match   = { initial_title = "^(.*Obsidian.*)$" },
  opacity = "0.99 override 0.99 override",
  xray    = true,
})
