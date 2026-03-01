{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  # CLI packages that work on both headless and desktop systems
  cliPkgs = with pkgs; [
    proton-pass-cli

    # Development tools
    nil # nix lsp
    stylua
    prettier
    delve
    fd
    gdb
    cling
    rustup
    python3
    nodejs
    alejandra # nix code formatter
    nixd
    docker-compose
    gcc
    gh # GitHub CLI
    gnumake
    go
    clojure
    claude-code
    cloudflared
    wakatime-cli

    # CLI utilities
    fastfetch
    figlet # cool text gen
    yazi # cli explorer
    colordiff # file diff
    lz4
    gitmoji-cli # emoji for commits
    glow # cli markdown renderer
    imagemagick
    onefetch # git repo summary
    openvpn
    pfetch-rs # system info
    # rcon # remote console
    sherlock
    skim # fzf in rust
    devenv
    sshs
    viddy # modern "watch"
    gum # fancy scripts
    tlrc # better man
    dialog
    iproute2
    netcat-gnu
    jq
    wl-clipboard
    # wakatime-cli
    awscli2

    # Shells & prompts
    starship
    oh-my-posh
    nushell
    fish
    zsh
    grc
  ];

  # GUI packages for desktop systems
  guiPkgs = with pkgs; [
    lollypop
    vscode
    chromium
    inputs.claude-desktop.packages.${stdenv.hostPlatform.system}.claude-desktop-with-fhs
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    jellyfin-desktop
    # Desktop utilities
    font-manager
    rnote
    egl-wayland # needed for firefox wayland fix
    wayvnc
    wvkbd # on-screen keyboard
    hyprshot
    wev # for keybindings
    scrcpy # android screen mirroring
    swayimg # image viewer
    playerctl # media controls
    libnotify
    loupe
    wireplumber # PipeWire session manager

    # Heavy GUI applications
    # krita # broken: lager/boost build failure
    libreoffice
    postman
    gnome-solanum
    mpv # video player
    ffmpeg-full
    # protonvpn-gui
    # proton-pass

    file-roller
    evince

    qbittorrent
    # calibre # broken: missing qmake in build
    (obsidian.override {commandLineArgs = ["--no-sandbox"];})
    inkscape
  ];
in {
  home = {
    username = "xhos";
    homeDirectory = "/home/xhos";
    stateVersion = "25.05";
    packages = lib.concatLists [
      cliPkgs
      (lib.optionals (config.headless != true) guiPkgs)
    ];
  };
}
