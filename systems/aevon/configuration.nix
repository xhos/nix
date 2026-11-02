{inputs, ...}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  profile = "full";

  virtualisation.docker.enable = true;

  wsl.enable = true;
  wsl.defaultUser = "xhos";

  networking.hostName = "aevon";
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
