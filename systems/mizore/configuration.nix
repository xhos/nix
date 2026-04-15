{inputs, config, ...}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  profile = "minimal";
  homelab.enable = true;
  homelab.null.enable = true;
  homelab.config.tailscaleIP = ""; # set after first tailscale up

  networking.hostName = "mizore";
  networking.hostId = "d75676d6";
  nixpkgs.hostPlatform = "x86_64-linux";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./mizore.pub];

  # CI deploy user — can only run nixos-rebuild switch
  users.users.deploy = {
    isSystemUser = true;
    group = "deploy";
    shell = "/bin/sh";
    openssh.authorizedKeys.keyFiles = [./deploy.pub];
  };
  users.groups.deploy = {};

  security.sudo.extraRules = [
    {
      users = ["deploy"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["NOPASSWD"];
        }
        {
          command = "/nix/store/*/bin/switch-to-configuration";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  nix.settings = {
    trusted-users = ["deploy"];
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
