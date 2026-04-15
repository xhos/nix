{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # minimal — every host gets this (debug, admin, nix ecosystem)
  essentialPkgs = with pkgs; [
    # Network debugging
    nmap
    dig
    openssl

    # Hardware & disk monitoring
    lm_sensors
    dysk
    ncdu
    procps

    # Nix ecosystem & secrets
    nh
    home-manager
    sops
    age

    # Version control
    git
    git-lfs

    # Shell essentials
    bat
    btop
    fzf
    ripgrep
    tree
    wget
    unzip
  ];

  # full — workhorses/desktops get this on top of essential
  fullCliPkgs = with pkgs; [
    caligula
    speedtest-cli
    wirelesstools
    fan2go
    nix-prefetch-git
    nix-inspect
    git-extras
    uv
    android-tools
    inputs.nxv.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # desktop — GUI systems only
  guiPkgs = with pkgs; [
    kdiskmark
    easyeffects
    brightnessctl
    xdg-utils
    gtk3
    kitty
    nautilus
    nautilus-python
  ];
in {
  environment.systemPackages = lib.concatLists [
    essentialPkgs
    (lib.optionals (config.profile != "minimal") fullCliPkgs)
    (lib.optionals (config.profile == "desktop") guiPkgs)
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    allowUnfreePredicate = _: true;
    android_sdk.accept_license = true;
  };

  # nautilus extension loading — only meaningful on desktop but harmless elsewhere
  environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR = lib.mkForce "/run/current-system/sw/lib/nautilus/extensions-4";
  environment.pathsToLink = ["/share/nautilus-python/extensions"];
}
