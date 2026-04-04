{
  inputs,
  lib,
  ...
}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  networking.hostName = "e2-micro";
  nixpkgs.hostPlatform = "x86_64-linux";

  virtualisation.diskSize = 20480;

  users.users.root.openssh.authorizedKeys.keyFiles = [../mizore/mizore.pub];
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  system.stateVersion = "25.11";
}
