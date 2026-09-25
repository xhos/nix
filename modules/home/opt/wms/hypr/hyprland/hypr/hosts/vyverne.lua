hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "11", monitor = "HDMI-A-2", default = true })

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
