{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: {
  programs.zed-editor = lib.mkIf (config.headless != true) {
    enable = true;

    extensions = [
      "catppuccin-blur"
      "docker-compose"
      "dockerfile"
      "git-firefly"
      "html"
      "log"
      "material-icon-theme"
      "min-theme"
      "nix"
      "ruff"
      "sql"
      "tokyo-night"
      "toml"
      "wakatime"
    ];

    extraPackages = [
      inputs.tsutsumi.packages.${pkgs.stdenv.hostPlatform.system}.wakatime-ls
      pkgs.alejandra
    ];

    userSettings = {
      base_keymap = "VSCode";
      vim_mode = false;
      theme = "Min Dark (Blurred)";
      icon_theme = "Material Icon Theme";

      ui_font_size = 18.0;
      buffer_font_family = "FiraCode Nerd Font Mono";
      buffer_font_size = 14.0;
      buffer_font_weight = 400.0;
      tab_size = 2;

      auto_update = false;
      autosave = "on_focus_change";
      format_on_save = "on";
      formatter = "language_server";
      relative_line_numbers = false;
      show_wrap_guides = true;

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      collaboration_panel.button = false;
      bottom_dock_layout = "contained";

      git = {
        inline_blame.enabled = false;
      };

      git_panel = {
        sort_by_path = false;
        collapse_untracked_diff = false;
        status_style = "label_color";
      };

      outline_panel = {
        dock = "right";
        button = true;
      };

      project_panel = {
        hide_hidden = false;
        hide_root = true;
        hide_gitignore = false;
        auto_fold_dirs = true;
        auto_reveal_entries = true;
        folder_icons = true;
        sticky_scroll = false;
        button = true;
        dock = "left";
        indent_size = 12;
        entry_spacing = "standard";
        indent_guides.show = "never";
        scrollbar.show = "never";
      };

      tab_bar = {
        show_nav_history_buttons = false;
        show = true;
      };

      tabs = {
        show_close_button = "hidden";
        show_diagnostics = "all";
        file_icons = false;
        git_status = false;
      };

      title_bar = {
        show_project_items = true;
        show_menus = false;
        show_user_picture = false;
        show_sign_in = false;
        show_branch_icon = true;
      };

      terminal = {
        font_family = "Hack Nerd Font Mono";
        font_size = 14.0;
        font_weight = 400.0;
        toolbar.breadcrumbs = false;
        button = false;
      };

      toolbar = {
        code_actions = true;
        quick_actions = true;
        breadcrumbs = true;
      };

      status_bar = {
        cursor_position_button = true;
        active_language_button = false;
      };

      gutter = {
        min_line_number_digits = 3;
        breakpoints = false;
        folds = false;
      };

      scrollbar.show = "never";

      minimap = {
        show = "always";
        display_in = "active_editor";
        thumb = "hover";
        thumb_border = "left_open";
        current_line_highlight = "all";
        max_width_columns = 60;
      };

      indent_guides = {
        enabled = true;
        coloring = "fixed";
        background_coloring = "disabled";
      };

      inlay_hints = {
        enabled = false;
        show_background = true;
      };

      preview_tabs.enable_preview_from_file_finder = false;
      search.button = false;
      debugger.button = true;
      diagnostics.button = true;
      file_finder.file_icons = true;

      features.edit_prediction_provider = "copilot";

      agent = {
        default_profile = "ask";
        default_model = {
          provider = "copilot_chat";
          model = "gemini-2.5-pro";
        };
        play_sound_when_agent_done = true;
      };

      agent_ui_font_size = 14.0;

      file_scan_exclusions = [
        ".pre-commit-config.yaml"
        ".direnv"
        ".git"
        ".envrc"
        ".claude"
        "CLAUDE.md"
      ];

      languages.Nix = {
        formatter = {
          external = {
            command = "alejandra";
            arguments = [];
          };
        };
      };
    };
  };
}
