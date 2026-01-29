{
  lib,
  config,
  inputs,
  pkgs,
  hostname,
  ...
}: {
  home.packages = let
    zed-discord = pkgs.rustPlatform.buildRustPackage rec {
      pname = "discord-presence-lsp";
      # TODO update version
      version = "eacb8afb406525a939a739c8c3a6834081bc9cb3";
      # cargoHash = "sha256-JLNCEeo9fKeV4vTtPs+Yj2wRO1RKP2fuetrPlXcPBjA=";
      cargoHash = "sha256-uc8ehP3D2HEMHzaDhOQ60I7hIzAOWvCLe50MAy0KjuY=";

      src = pkgs.fetchFromGitHub {
        owner = "xhyrom";
        repo = "zed-discord-presence";
        rev = version;
        hash = "sha256-HJUoeY5fZV3Ku+ec32dHUYgP968Vdeevh6aAz9F8Ggs=";
      };

      cargoBuildFlags = "--package discord-presence-lsp";
    };
  in [
    inputs.tsutsumi.packages.${pkgs.system}.wakatime-ls
    zed-discord
  ];

  programs.zed-editor = lib.mkIf (config.headless != true) {
    enable = true;

    extensions = [
      # custom pkgs needed
      "discord-presence"
      "wakatime"

      # themes
      "catppuccin-blur"
      "gruvbox-material-mix"
      "material-icon-theme"
      "min-theme"
      "tokyo-night"

      # languages
      "docker-compose"
      "git-firefly"
      "dockerfile"
      "toml"
      "html"
      "log"
      "nix"
      "ruff"
      "sql"
    ];

    extraPackages = with pkgs; [
      inputs.tsutsumi.packages.${pkgs.stdenv.hostPlatform.system}.wakatime-ls
      alejandra
      nil
      nixd
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

      lsp = {
        nixd = {
          binary = {
            path_lookup = true;
          };
          initialization_options = {
            diagnostics.suppress = ["sema-extra-with"];
            nixpkgs.expr = ''import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { }'';
            options = {
              nixos.expr = ''(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${hostname}.options'';
              home_manager.expr = ''(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${hostname}.options.home-manager.users.type.getSubOptions []'';
            };
            flake_parts.expr = ''let flake = builtins.getFlake ((builtins.toString ./.)); in flake.debug.options // flake.currentSystem.options'';
          };
        };
        nil = {
          binary = {
            path_lookup = true;
          };
          initialization_options = {
            diagnostics.ignored = ["unused_binding"];
            nix = {
              maxMemoryMB = 4096;
              flake = {
                autoArchive = true;
                autoEvalInputs = true;
                nixpkgsInputName = "nixpkgs";
              };
            };
          };
        };
      };
      languages = {
        Nix = {
          language_servers = [
            "!nil"
            "nixd"
          ];
          formatter = {
            external = {
              command = "alejandra";
              arguments = [
                "--quiet"
                "--"
              ];
            };
          };
        };
      };
    };
  };
}
