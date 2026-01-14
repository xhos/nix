{
  inputs,
  lib,
  config,
  ...
}: let
  persistIf = condition: persistConfig: lib.mkIf condition persistConfig;
  moduleEnabled = module: config.modules.${module}.enable or false;
in {
  imports = [inputs.impermanence.homeManagerModules.impermanence];

  options.impermanence.enable = lib.mkEnableOption "wipe home folder on reboot, persist selected directories";

  options.persist = {
    dirs = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [];
      description = "dirs to persist";
    };

    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "files to persist";
    };
  };

  config = {
    home.activation.fixPathForImpermanence = lib.hm.dag.entryBefore ["cleanEmptyLinkTargets"] ''
      PATH=$PATH:/run/wrappers/bin
    '';

    home.persistence."/persist/home/xhos" = lib.mkIf config.impermanence.enable (lib.mkMerge [
      {
        directories =
          [
            ".npm" # then npm cache cannot be configured to be in the projects dir and its insane in size, it sucks.
            "go" # same for go
            ".local/share/zed"
            ".local/share/nautilus" # nautilus bookmarks
            ".config/teams-for-linux"
            ".config/claude"
            ".local/state/wireplumber"

            # jetbrains
            ".local/share/JetBrains"
            ".config/JetBrains"
            ".cache/JetBrains"
            ".java" # jetbrains for some miraculous reason stores auth here

            # claude
            ".claude"
            ".config/Claude/"

            # misc configs
            ".config/pulse"
            ".config/libreoffice"
            ".config/spotify"
            ".config/calibre"
            ".config/clipse"
            ".config/Code"
            ".config/obsidian"
            ".config/chromium"
            ".config/github-copilot" # zed stores its copilot auth here
            ".config/sops"
            ".config/nvim"
            ".config/obs-studio"

            ".local/share/PrismLauncher"
            ".local/share/direnv"
            ".local/share/zoxide" # zoxide i lv u, plz don't hv amnesia

            # should techically be only enabled when steam is but oh well
            ".config/r2modmanPlus-local"
            ".config/r2modman"

            ".local/share/nvim"
            ".local/state/nvf/"
            ".zen"
            ".ssh"
            ".mozilla"
            ".vscode"
            "work"
            "Projects"
            "Music"
            "Documents"
            "Downloads"
            "Pictures"
            "Videos"

            # big caches
            ".cache/go-build"
            ".cache/.bun"
            ".cache/spotify"
            ".cache/huggingface"
            ".cache/Proton" # proton stores their login stuff in cache for some reason

            ".config/zsh"
            ".local/share/zsh"
            ".config/OpenRGB"

            # misc state
            ".local/state/lazygit"
          ]
          ++ config.persist.dirs;

        files = [] ++ config.persist.files;

        allowOther = true;
      }

      (persistIf (moduleEnabled "telegram") {
        directories = [
          ".local/share/materialgram/tdata"
          ".cache/stylix-telegram-theme"
        ];
      })

      (persistIf (moduleEnabled "discord") {
        directories = [
          ".config/discord"
        ];
      })

      (lib.mkIf (config.de == "hyprland") {
        files = [
          ".config/hypr/monitors.conf"
        ];
      })

      (persistIf config.headless {
        directories = [
          ".cloudflared"
          ".vscode-server"
          ".zed_server"
          {
            # podman stores its volumes here
            directory = ".local/share/containers";
            method = "symlink";
          }
        ];
      })
    ]);
  };
}
