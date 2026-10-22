{
  config,
  lib,
  ...
}: {
  options.homelab.wakapi.enable = lib.mkEnableOption "enable wakapi server";

  config = lib.mkIf config.homelab.wakapi.enable {
    sops.secrets."env/wakapi" = {};

    systemd.services.wakapi = {
      requires = ["postgresql.target"];
      after = ["postgresql.target"];
      # unset dynamic user stuff which makes it difficult to persist
      serviceConfig = {
        StateDirectory = lib.mkForce null;
        DynamicUser = lib.mkForce false;
        User = "wakapi";
        Group = "wakapi";
      };
    };

    services.postgresql = {
      ensureDatabases = ["wakapi"];
      ensureUsers = [
        {
          name = "wakapi";
          ensureDBOwnership = true;
        }
      ];
    };

    homelab.exposedServices.wakapi = {
      port = 3333;
      exposed = true;
      dashboard.group = "personal";
    };

    services.wakapi = {
      enable = true;
      environmentFiles = [config.sops.secrets."env/wakapi".path];

      settings = {
        server.port = 3333;

        # createLocally would add a passwordless tcp trust rule; use peer auth instead
        db = {
          dialect = "postgres";
          DSN = "host=/run/postgresql user=wakapi dbname=wakapi sslmode=disable";
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
