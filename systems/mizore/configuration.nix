{inputs, ...}: {
  hosts.mizore = {
    homeUser = null;
    features = with inputs.self.modules.nixos; [tailnet];

    nixos = {inputs, ...}: {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
      ];

      profile = "minimal";
      homelab.enable = true;

      networking.hostName = "mizore";
      networking.hostId = "d75676d6";
      nixpkgs.hostPlatform = "x86_64-linux";

      users.users.xhos.openssh.authorizedKeys.keyFiles = [./mizore.pub];

      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
      };

      system.stateVersion = "25.11";
    };
  };
}
