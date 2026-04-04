{inputs, ...}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  networking.hostName = "proxy-1";
  networking.hostId = "6e172669";
  nixpkgs.hostPlatform = "x86_64-linux";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./proxy.pub];

  system.stateVersion = "25.11";
}
