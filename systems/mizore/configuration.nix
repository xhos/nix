{inputs, ...}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  profile = "minimal";
  homelab.enable = true;
  homelab.trek.enable = true;
  homelab.config.tailscaleIP = "100.64.0.13";

  networking.hostName = "mizore";
  networking.hostId = "d75676d6";
  nixpkgs.hostPlatform = "x86_64-linux";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./mizore.pub];

  nix.settings = {
    substituters = ["https://cache.xhos.dev/main"];
    trusted-public-keys = ["main:sD+aH0XOgkp432O05lkkl1x7XipgELXk+1mQmuDch0U="];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  system.stateVersion = "25.11";
}
