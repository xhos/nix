{
  config,
  lib,
  ...
}: {
  options.homelab.wakapi.enable = lib.mkEnableOption "enable wakapi server";

  config = lib.mkIf config.homelab.wakapi.enable {
    sops.secrets."env/wakapi" = {};

    # unset dynamic user stuff which makes it difficult to persist
    systemd.services.wakapi.serviceConfig = {
      StateDirectory = lib.mkForce null;
      DynamicUser = lib.mkForce false;
      User = "wakapi";
      Group = "wakapi";
    };

    homelab.exposedServices.wakapi = {
      port = 3333;
      exposed = true;
    };

    services.wakapi = {
      enable = true;
      database.createLocally = true;
      environmentFiles = [config.sops.secrets."env/wakapi".path];

      settings = {
        server.port = 3333;

        db = {
          dialect = "postgres";
          host = "127.0.0.1";
          name = "wakapi";
          user = "wakapi";
          port = 5432;
        };

        mail.enabled = false;

        security = {
          allow_signup = false;
          invite_codes = true;
          disable_frontpage = true;
        };
      };
    };
  };
}
