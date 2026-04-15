{
  config,
  pkgs,
  lib,
  ...
}: {
  options.homelab.trek.enable = lib.mkEnableOption "enable trek";

  config = lib.mkIf config.homelab.trek.enable {
    sops.secrets."env/trek" = {};

    homelab.exposedServices.trek = {
      port = 3000;
      exposed = true;
    };

    homelab.backup.services.trek = {
      paths = [
        "/var/lib/trek/data"
        "/var/lib/trek/uploads"
      ];
    };

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = false;
    };

    # to update
    # sudo podman pull mauriceboe/trek:latest
    # sudo systemctl restart podman-trek.service
    #
    virtualisation.oci-containers = {
      backend = "podman";
      containers.trek = {
        image = "ghcr.io/xhos/trek-with-map-drawing:latest";
        ports = ["127.0.0.1:3000:3000"];
        environment = {
          NODE_ENV = "production";
          PORT = "3000";
          FORCE_HTTPS = "true";
          TRUST_PROXY = "1";
          ALLOW_INTERNAL_NETWORK = "false";
          ALLOWED_ORIGINS = "https://trek.${config.homelab.config.domain}";
        };
        environmentFiles = [config.sops.secrets."env/trek".path];
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

    # Pre-backup SQLite dump for consistent snapshots
    systemd.services.restic-dump-trek = {
      description = "Dump Trek SQLite database before backup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "dump-trek" ''
          mkdir -p /var/backup/trek
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/trek/data/trek.db ".backup '/var/backup/trek/trek.db'"
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/trek 0750 root root -"
      "d /var/lib/trek/data 0750 root root -"
      "d /var/lib/trek/uploads 0777 root root -"
      "d /var/lib/trek/uploads/avatars 0777 root root -"
      "d /var/backup/trek 0750 root root -"
    ];

    homelab.firewall.extraForwardRules = ''
      iifname "podman0" accept
      oifname "podman0" accept
    '';

    homelab.firewall.extraPostroutingRules = ''
      ip saddr 10.88.0.0/16 masquerade
    '';
  };
}
