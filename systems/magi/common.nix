# shared config for the magi cluster: three dell optiplex 5040s (melchior, balthasar, casper)
{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disko.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  profile = "minimal";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings = {
    substituters = ["https://cache.xhos.dev/main"];
    trusted-public-keys = ["main:sD+aH0XOgkp432O05lkkl1x7XipgELXk+1mQmuDch0U="];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  system.stateVersion = "26.11";
}
