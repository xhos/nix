{
  flake.modules.nixos.games = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      prismlauncher
      wineWow64Packages.stable
      winetricks
      lutris
      r2modman
    ];

    programs.steam = {
      enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin proton-ge-9-20];
    };

    services.zerotierone = {
      enable = true;
      joinNetworks = ["abfd31bd47fb27ef"];
    };

    persist.dirs = ["/var/lib/zerotier-one"];

    # home paths must go through users.<name> so parent dirs (.local, .local/share)
    # are created owned by xhos, not root
    environment.persistence."/persist".users.xhos.directories = [
      ".steam"
      ".local/share/Steam"
    ];
  };

  flake.modules.homeManager.games = {
    home.sessionVariables.WINEDLLOVERRIDES = "winemenubuilder.exe=d"; # no wine file associations

    persist.dirs = [
      ".wine"
      ".local/share/PrismLauncher"
      ".local/share/lutris"
      ".local/share/umu"
      ".config/r2modman"
      ".config/r2modmanPlus-local"
      ".config/unity3d"
    ];
  };
}
