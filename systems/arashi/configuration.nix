{
  inputs,
  lib,
  ...
}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  networking.hostName = "arashi";
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
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

  homelab = {
    enable = true;
    immich.enable = true;
    config.tailscaleIP = "100.64.0.1";
  };

  # trek
  sops.secrets."env/trek" = {};

  homelab.exposedServices.trek = {
    port = 3000;
    exposed = true;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = false;
  };

  # to update
  # sudo podman pull mauriceboe/trek:latest
  # sudo systemctl restart podman-trek.service

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
        "--dns=1.1.1.1"
        "--dns=1.0.0.1"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/trek 0750 root root -"
    "d /var/lib/trek/data 0750 root root -"
    "d /var/lib/trek/uploads 0777 root root -"
    "d /var/lib/trek/uploads/avatars 0777 root root -"
  ];

  # open 80/443 for direct access (headscale needs to be reachable
  # without tailscale) and 41641 for tailscale derp
  homelab.firewall.extraInputRules = ''
    tcp dport { 80, 443 } accept
    udp dport { 41641 } accept
  '';

  homelab.firewall.extraForwardRules = ''
    iifname "podman0" accept
    oifname "podman0" accept
  '';

  homelab.firewall.extraPostroutingRules = ''
    ip saddr 10.88.0.0/16 masquerade
  '';

  services.tailscale.extraUpFlags = lib.mkForce ["--login-server" "http://127.0.0.1:8080"];

  systemd.services.tailscaled-autoconnect = {
    after = ["headscale.service"];
    requires = ["headscale.service"];
  };

  system.stateVersion = "25.11";
}
