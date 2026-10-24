# shared config for the magi cluster: three dell optiplex 5040s (melchior, balthasar, casper)
{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disko.nix {}) # module args ignore defaults, call it so disk ? applies
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  profile = "minimal";
  # homelab.forgejo-runner.enable = true;

  # stable nic name, same as enrai
  systemd.network.links."10-lan0" = {
    matchConfig = {
      Type = "ether";
      Path = "pci-*";
    };
    linkConfig.Name = "lan0";
  };

  networking.defaultGateway = "10.0.0.1";

  # key-only ssh, so the password adds nothing; lets deploy-rs activate unattended
  security.sudo.wheelNeedsPassword = false;

  # failed key attempts from lan/tailnet hosts shouldn't lock them out
  services.fail2ban.ignoreIP = ["10.0.0.0/24" "100.64.0.0/10"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  system.stateVersion = "26.11";
}
