{
  lib,
  config,
  ...
}: let
  persistIf = condition: persistConfig: lib.mkIf condition persistConfig;
  moduleEnabled = module: config.modules.${module}.enable or false;
in {
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

    home.persistence."/persist" = lib.mkIf config.impermanence.enable (lib.mkMerge [
      {
        directories =
          [
            # --- configs ---
            ".aws"
            ".config/git"
            ".config/qBittorrent"

            # github/copilot
            ".copilot"
            ".config/gh"

            # --- state ---
            ".local/state/lazygit"
            ".local/state/nvf/"

            ".local/share/nvf"
            ".local/share/zsh"
            ".local/share/PrismLauncher"
            ".local/share/direnv"
            ".local/share/zoxide" # zoxide i lv u, plz don't hv amnesia
            ".local/share/nvim"
            ".local/share/DaVinciResolve"

            # lutris
            ".local/share/umu" # todo: is this lutris tho
            ".local/share/lutris"

            ".cache/zen"
            ".wine"

            # android fucking studio (i hate it)
            "Android"
            ".config/Google"
            ".cache/Google"
            ".gradle"
            ".config/.android"

            ".local/share/jellyfin-desktop"
            ".config/niri"
            "nix"
            ".npm" # then npm cache cannot be configured to be in the projects dir and its insane in size, it sucks.
            "go" # same for go
            ".local/share/zed"
            ".local/share/proton-pass-cli"
            ".local/share/keyrings" # gnome-keyring; without this every reboot wipes it and apps re-prompt to create one

            # nautilus bookmarks
            ".local/share/nautilus"
            ".config/gtk-3.0/"
            ".local/state/wireplumber"

            # jetbrains
            ".local/share/JetBrains"
            ".config/JetBrains"
            ".cache/JetBrains"
            ".java" # jetbrains for some miraculous reason stores auth here

            # misc configs
            ".config/pulse"
            ".config/libreoffice"
            ".config/teams-for-linux"
            ".config/zsh"
            ".config/OpenRGB"
            ".config/claude"
            ".config/spotify"
            ".config/calibre"
            ".config/Code"
            ".config/obsidian"
            ".config/chromium"
            ".config/github-copilot" # zed stores its copilot auth here
            ".config/sops"
            ".config/nvim"
            ".config/obs-studio"

            # should techically be only enabled when steam is but oh well
            ".config/r2modmanPlus-local"
            ".config/r2modman"

            ".zen"
            ".ssh"
            ".mozilla"
            ".vscode"
            "work" # todo: unemployed, remove once i mover stuff on vyverne out of there

            # the regular toplevels
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
          ]
          ++ config.persist.dirs;

        files = [] ++ config.persist.files;
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

      (lib.mkIf (config.wm == "hyprland") {
        files = [
          ".config/hypr/monitors.conf"
        ];
      })

      (persistIf config.headless {
        directories = [
          ".cloudflared"
          ".vscode-server"
          ".zed_server"
          ".local/share/containers" # podman containers
        ];
      })
    ]);
  };
}
