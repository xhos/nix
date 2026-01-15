{
  config,
  lib,
  ...
}: {
  options.modules.rofi.enable = lib.mkEnableOption "rofi application launcher";

  config = lib.mkIf config.modules.rofi.enable {
    programs.rofi = {
      enable = true;
      theme = let
        inherit (config.lib.formats.rasi) mkLiteral;
        mkl = mkLiteral;
      in {
        "*" = {
          font = mkl "\"Hack Nerd Font 12\"";
          bg0 = mkl "#${config.lib.stylix.colors.base00}55";
          bg1 = mkl "#${config.lib.stylix.colors.base01}55";
          bg2 = mkl "#${config.lib.stylix.colors.base0E}55";
          fg0 = mkl "#${config.lib.stylix.colors.base06}";
          fg1 = mkl "#${config.lib.stylix.colors.base07}";
          fg2 = mkl "#${config.lib.stylix.colors.base05}55";
          background-color = mkl "transparent";
          text-color = mkl "@fg0";
          margin = 0;
          padding = 0;
          spacing = 0;
        };

        "window" = {
          background-color = mkl "@bg0";
          location = mkl "center";
          width = 640;
          border-radius = 8;
        };

        "inputbar" = {
          font = mkl "\"Hack Nerd Font 20\"";
          padding = mkl "12px";
          spacing = mkl "12px";
          children = map mkl ["entry"];
        };

        "entry, element-icon, element-text" = {
          vertical-align = mkl "0.5";
        };

        "entry" = {
          font = mkl "inherit";
          placeholder = mkl "\"Search\"";
          placeholder-color = mkl "@fg2";
        };

        "message" = {
          border = mkl "2px 0 0";
          border-color = mkl "@bg1";
          background-color = mkl "@bg1";
        };

        "textbox" = {
          padding = mkl "8px 24px";
        };

        "listview" = {
          lines = 10;
          columns = 1;
          fixed-height = false;
          border = mkl "1px 0 0";
          border-color = mkl "@bg1";
        };

        "element" = {
          padding = mkl "8px 16px";
          spacing = mkl "16px";
          background-color = mkl "transparent";
        };

        "element normal active" = {
          text-color = mkl "@bg2";
        };

        "element alternate active" = {
          text-color = mkl "@bg2";
        };

        "element selected normal, element selected active" = {
          background-color = mkl "@bg2";
          text-color = mkl "@fg1";
        };

        "element-icon" = {
          size = mkl "1em";
        };

        "element-text" = {
          text-color = mkl "inherit";
        };
      };
    };
  };
}
