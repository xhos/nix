{inputs, ...}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  networking.hostName = "arashi";
  networking.hostId = "3891dea5";

  nixpkgs.hostPlatform = "aarch64-linux";

  headless = true;

  virtualisation.diskSize = 20480;

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./arashi.pub];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8080;
    settings = {
      server_url = "https://hs.xhos.dev";
      ip_prefixes = ["100.64.0.0/10"];
      dns = {
        magic_dns = true;
        base_domain = "lab.xhos.dev";
        nameservers.global = ["1.1.1.1" "1.0.0.1"];
      };
    };
  };

  services.caddy = {
    enable = true;
    email = "lets-encrypt@xhos.dev";
  };

  services.caddy.virtualHosts."hs.xhos.dev".extraConfig = ''
    reverse_proxy 127.0.0.1:8080
  '';

  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [41641];

  system.stateVersion = "25.11";
}
