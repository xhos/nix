{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # CLI packages useful on both headless and desktop systems
  cliPkgs = with pkgs; [
    # Networking tools
    nmap
    speedtest-cli
    dig # dns lookup
    openssl
    wirelesstools # wireless utilities (useful for headless WiFi setup too)

    # Hardware monitoring
    lm_sensors
    fan2go
    dysk

    # Nix ecosystem tools
    nh # nix helper
    home-manager
    nix-prefetch-git
    nix-inspect

    # Version control
    git
    git-lfs
    git-extras

    # Security & secrets
    age # file encryption
    sops # secrets encryption

    # CLI utilities
    bat # cat but better
    btop
    fzf
    procps # process info
    ncdu # disk usage
    ripgrep # recursively searches directories for regex patterns
    wget
    unzip
    inputs.nxv.packages.${pkgs.stdenv.hostPlatform.system}.default

    tree
    uv
    android-tools
  ];

  # GUI packages for desktop systems only
  guiPkgs = with pkgs; [
    kdiskmark
    easyeffects # pipewire audio effects

    brightnessctl # screen brightness control
    xdg-utils # desktop integration utilities
    gtk3 # GUI toolkit
    kitty # fallback terminal
    nautilus
    nautilus-python
  ];
in {
  environment.systemPackages = lib.concatLists [
    cliPkgs
    (lib.optionals (config.headless != true) guiPkgs)
  ];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    allowUnfreePredicate = _: true;
    android_sdk.accept_license = true;
  };

  # # --------nautilis shenanigans----------
  # # refernces:
  # # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/nautilus-open-any-terminal.nix
  # # https://www.reddit.com/r/NixOS/comments/1qnw2t0/nautilus_and_openanyterminal_doa/

  # Load regular extensions
  environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR = lib.mkForce "/run/current-system/sw/lib/nautilus/extensions-4";

  # Load Python extensions via the nautilus-python extension
  environment.pathsToLink = ["/share/nautilus-python/extensions"];

  # Ghostty has a built "Open in Ghostty" nautilus extension, it's loaded only when 2 above lines are present
  # --------------------------------------
}
