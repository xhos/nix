-- Reserve each monitor's ten-workspace block before monitors are initialized.
for workspace = 1, 20 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = workspace <= 10 and "HDMI-A-1" or "HDMI-A-2",
    default = (workspace == 1 or workspace == 11) or nil,
  })
end

hl.window_rule({
  match     = { initial_class = "^(spotify)$" },
  workspace = "special silent",
})

hl.window_rule({
  match     = { initial_title = "^(materialgram)$" },
  workspace = "10 silent",
})

hl.window_rule({
  match     = { initial_class = "^(discord)$" },
  workspace = "10 silent",
})
