{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.proxmox-nixos.nixosModules.proxmox-ve
    inputs.vpn-confinement.nixosModules.default
    inputs.vscode-server.nixosModules.default
    inputs.wled-album-sync.nixosModules.default
    ./hardware-configuration.nix
    ./disko.nix
  ];
  users.users.root.initialHashedPassword = "$y$j9T$iDTgP1si33HTwRpAPY2r1/$y1LJRFAgrqAgXhCH/Y/pvYu.X0snt306UZmoGksWhR4";
  networking.hostName = "enrai";
  networking.hostId = "8a1e0ee2";
  nixpkgs.hostPlatform = "x86_64-linux";

  impermanence.enable = true;
  headless = true;

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.vscode-server.enable = true;

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./enrai.pub];

  services.openssh.settings.AcceptEnv = lib.mkForce ["LANG" "LC_*"];

  # services.cloudflared = {
  #   enable = true;
  #   tunnels = let
  #     tunnel-id = "efa05949-86bc-4b7e-8b28-acc3fc97fb08";
  #   in {
  #     "${tunnel-id}" = {
  #       credentialsFile = "/home/xhos/.cloudflared/${tunnel-id}.json";
  #       ingress = {
  #         "ssh.xhos.dev" = "ssh://localhost:10022";
  #       };
  #       default = "http_status:404";
  #     };
  #   };
  # };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # compressed RAM swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };
}
