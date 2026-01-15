{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.headless != true) {
    home.file.".config/clipse/custom_theme.json".text = ''      {
         "UseCustom":          false,
         "TitleFore":          "#${config.text}",
         "TitleBack":          "#${config.peach}",
         "TitleInfo":          "#${config.teal}",
         "NormalTitle":        "#${config.text}",
         "DimmedTitle":        "#${config.surface2}",
         "SelectedTitle":      "#${config.accent}",
         "NormalDesc":         "#${config.surface2}",
         "DimmedDesc":         "#${config.surface2}",
         "SelectedDesc":       "#${config.accent}",
         "StatusMsg":          "#${config.green}",
         "PinIndicatorColor":  "#${config.yellow}",
         "SelectedBorder":     "#${config.teal}",
         "SelectedDescBorder": "#${config.teal}",
         "FilteredMatch":      "#${config.text}",
         "FilterPrompt":       "#${config.green}",
         "FilterInfo":         "#${config.teal}",
         "FilterText":         "#${config.text}",
         "FilterCursor":       "#${config.yellow}",
         "HelpKey":            "#${config.surface2}",
         "HelpDesc":           "#${config.surface2}",
         "PageActiveDot":      "#${config.teal}",
         "PageInactiveDot":    "#${config.surface2}",
         "DividerDot":         "#${config.teal}",
         "PreviewedText":      "#${config.text}",
         "PreviewBorder":      "#${config.teal}",
       }'';
  };
}
