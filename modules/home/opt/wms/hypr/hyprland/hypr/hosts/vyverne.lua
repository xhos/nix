hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "11", monitor = "HDMI-A-2", default = true })
hl.workspace_rule({ workspace = "12", monitor = "HDMI-A-2", layout = "dwindle" })

hl.window_rule({
  match     = { initial_class = "^(spotify)$" },
  workspace = "special silent",
})

hl.window_rule({
  match     = { initial_class = "^(io.github.kukuruzka165.materialgram)$" },
  workspace = "12 silent",
})

hl.window_rule({
  match     = { initial_class = "^(vesktop|discord)$" },
  workspace = "12 silent",
})

-- Restore the captured portrait layout whenever either app opens, regardless
-- of launch order: Materialgram above Discord, with content heights 567/1319.
local function arrange_chat()
  local telegram, discord
  local windows = hl.get_windows({ workspace = "12", floating = false, mapped = true })
  if #windows ~= 2 then return end

  for _, w in ipairs(windows) do
    if w.class == "io.github.kukuruzka165.materialgram" then
      telegram = w
    elseif w.class == "vesktop" or w.class == "discord" then
      discord = w
    end
  end
  if not telegram or not discord then return end
  if telegram.fullscreen ~= 0 or discord.fullscreen ~= 0 then return end

  if telegram.at.y == discord.at.y then
    local focused = hl.get_active_window()
    hl.dispatch(hl.dsp.focus({ window = telegram }))
    hl.dispatch(hl.dsp.layout("togglesplit"))
    if focused then hl.dispatch(hl.dsp.focus({ window = focused })) end
  end
  if telegram.at.y > discord.at.y then
    hl.dispatch(hl.dsp.window.swap({ window = telegram, target = discord }))
  end

  local height = telegram.size.y + discord.size.y
  hl.dispatch(hl.dsp.window.resize({
    window = telegram,
    x = telegram.size.x,
    y = math.floor(height * 567 / (567 + 1319) + 0.5),
  }))
end

hl.on("window.open", function(w)
  if w.class == "io.github.kukuruzka165.materialgram" or w.class == "vesktop" or w.class == "discord" then
    -- Run after the new window has joined the tiling tree.
    hl.timer(arrange_chat, { timeout = 100, type = "oneshot" })
  end
end)
arrange_chat()
