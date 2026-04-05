{inputs, ...}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  headless = true;

  networking.hostName = "mizore";
  networking.hostId = "d75676d6";
  nixpkgs.hostPlatform = "x86_64-linux";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./mizore.pub];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # trek
  sops.secrets."env/trek" = {};

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.trek = {
      image = "mauriceboe/trek:latest";
      ports = ["127.0.0.1:3000:3000"];
      environment = {
        NODE_ENV = "production";
        PORT = "3000";
        FORCE_HTTPS = "true";
        TRUST_PROXY = "1";
        ALLOW_INTERNAL_NETWORK = "false";
        ALLOWED_ORIGINS = "https://trek.xhos.dev";
      };
      environmentFiles = ["/run/secrets/env/trek"];
      volumes = [
        "/var/lib/trek/data:/app/data"
        "/var/lib/trek/uploads:/app/uploads"
      ];
      extraOptions = [
        "--read-only"
        "--security-opt=no-new-privileges:true"
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=SETUID"
        "--cap-add=SETGID"
        "--tmpfs=/tmp:noexec,nosuid,size=64m"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/trek 0750 root root -"
    "d /var/lib/trek/data 0750 root root -"
    "d /var/lib/trek/uploads 0750 root root -"
  ];

  services.caddy = {
    enable = true;
    email = "lets-encrypt@xhos.dev";
  };

  services.caddy.virtualHosts."trek.xhos.dev".extraConfig = ''
    reverse_proxy 127.0.0.1:3000
  '';

  networking.firewall.allowedTCPPorts = [80 443];

  system.stateVersion = "25.11";
}
