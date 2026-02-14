{
  inputs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "vyverne";
  networking.hostId = "9a7bef04";

  impermanence.enable = true;
  audio.enable = true;
  bluetooth.enable = true;
  games.enable = true;
  nvidia.enable = true;
  vm.enable = true;
  ai.enable = false;
  obs.enable = true;
  boot.enable = true;
  syncthing.enable = true;

  greeter = "yawn";
  terminal = "ghostty";
  wm = "hyprland";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./vyverne.pub];

  services.hardware.openrgb.enable = true;
  programs.kdeconnect.enable = true;

  # use android phone as a webcam
  boot.kernelModules = ["v4l2loopback"];
  boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Phone Cam"
  '';

  systemd.tmpfiles.rules = [
    "d /games 0755 xhos users - -"
  ];

  networking.interfaces.enp4s0.wakeOnLan.enable = true;

  # fix fn keys not working on infi75
  boot.kernelParams = ["hid_apple.fnmode=2"];
  boot.supportedFilesystems = ["zfs"];
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # allow poweroff/reboot over ssh without sudo
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.reboot") &&
          subject.user == "xhos") {
        return polkit.Result.YES;
      }
    });
  '';

  nixpkgs.overlays = [
    (final: prev: {
      ctranslate2 = prev.ctranslate2.override {
        withCUDA = true;
        withCuDNN = true;
      };
    })
  ];

  # downloading ram
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # up to 50% of RAM as compressed swap
  };
}
