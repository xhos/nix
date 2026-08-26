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
