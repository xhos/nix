{inputs, ...}: {
  hosts.arashi = {
    features = with inputs.self.modules.nixos; [tailnet];

    nixos = {inputs, ...}: {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
      ];

      networking.hostName = "arashi";
      networking.hostId = "3891dea5";

      nixpkgs.hostPlatform = "aarch64-linux";

      profile = "full";

      homelab.enable = true;

      users.users.xhos.openssh.authorizedKeys.keyFiles = [./arashi.pub];

      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 25;
      };

      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

      system.stateVersion = "25.11";
    };

    home = {pkgs, ...}: {
      headless = true;
      modules.secrets.enable = true;

      shell = "zsh";
      prompt = "starship";
      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
    };
  };
}
