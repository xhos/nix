{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  # minimal — bare comfort for ssh-ing in and operating
  essentialPkgs = with pkgs; [
    # Core utils
    fd
    jq
    iproute2
    netcat-gnu
    colordiff
    lz4
    dialog

    # Shell QoL
    fastfetch
    glow
    tlrc
    gum
    viddy
    sshs
    starship

    # Version control
    gh
    gnumake
  ];

  # full — dev workstation CLI (languages, toolchains, debuggers, cloud tools)
  fullCliPkgs = with pkgs; [
    # Nix dev
    nil
    nixd
    alejandra

    # Languages & toolchains
    rustup
    go
    nodejs
    python3
    clojure
    gcc
    gdb
    delve
    cling

    # Formatters
    stylua
    prettier

    # Containers & dev envs
    docker-compose
    devenv

    # Cloud & IaC
    awscli2
    opentofu
    cloudflared

    # Tunnels & VPN
    openvpn

    # Shells & prompts
    oh-my-posh
    nushell
    fish
    grc

    # Extras
    proton-pass-cli
    wakatime-cli
    figlet
    gitmoji-cli
    imagemagick
    onefetch
    pfetch-rs
    sherlock
    skim
    yazi
  ];

  # desktop — GUI apps
  guiPkgs = with pkgs; [
    # Browsers & editors
    vscode
    chromium
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default

    # Media
    lollypop
    jellyfin-desktop
    mpv
    ffmpeg-full
    playerctl
    loupe
    swayimg

    # Wayland/Hyprland utils
    wl-clipboard
    egl-wayland
    wayvnc
    wvkbd
    hyprshot
    wev
    libnotify
    wireplumber

    # Desktop apps
    amnezia-vpn
    gimp
    calibre
    font-manager
    rnote
    scrcpy
    libreoffice
    postman
    gnome-solanum
    file-roller
    evince
    qbittorrent
    inkscape
    (obsidian.override {commandLineArgs = ["--no-sandbox"];})
  ];
in {
  home = {
    username = "xhos";
    homeDirectory = "/home/xhos";
    stateVersion = "25.05";
    packages = lib.concatLists [
      essentialPkgs
      (lib.optionals (config.profile != "minimal") fullCliPkgs)
      (lib.optionals (config.profile == "desktop") guiPkgs)
    ];
  };
}
