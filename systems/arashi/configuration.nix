{inputs, ...}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  networking.hostName = "arashi";
  networking.hostId = "3891dea5";

  nixpkgs.hostPlatform = "aarch64-linux";

  profile = "full";

  homelab = {
    enable = true;
    immich.enable = true;
    attic.enable = true;
    trek.enable = true;
    config.tailscaleIP = "100.64.0.3";
  };

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./arashi.pub];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  system.stateVersion = "25.11";
}
