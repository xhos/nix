{
  config,
  lib,
  ...
}: {
  options.homelab.zipline.enable = lib.mkEnableOption "zipline file upload service";

  config = lib.mkIf config.homelab.zipline.enable {
    homelab.exposedServices.pics = {
      port = 3334;
      exposed = true;
      name = "zipline";
      dashboard = {
        group = "personal";
        icon = "https://cdn.jsdelivr.net/gh/selfhst/icons/png/zipline.png";
      };
    };

    sops.secrets."env/zipline" = {};

    # db is covered by the postgres dump; this holds uploads
    persist.dirs = ["/var/lib/zipline"];
    homelab.backup.services.zipline = {
      paths = ["/var/lib/zipline"];
      exclude = ["/var/lib/zipline/uploads/.tmp"];
    };

    # static user so the persisted /var/lib/zipline bind mount works
    systemd.services.zipline.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "zipline";
      Group = "zipline";
    };

    users.users.zipline = {
      isSystemUser = true;
      group = "zipline";
    };
    users.groups.zipline = {};

    services.zipline = {
      enable = true;
      environmentFiles = [config.sops.secrets."env/zipline".path];

      settings = {
        CORE_HOSTNAME = "127.0.0.1";
        CORE_PORT = 3334;
        EXIF_REMOVE_GPS = "true";
        FEATURES_ROBOTS_TXT = "true";
        MFA_TOTP_ISSUER = "xhos's zipline";
        MFA_TOTP_ENABLED = "true";
        RATELIMIT_ADMIN = "0";
        UPLOADER_DEFAULT_FORMAT = "RANDOM";
        UPLOADER_ROUTE = "/u";
        UPLOADER_LENGTH = "8";
        UPLOADER_ASSUME_MIMETYPES = "true";
        URLS_ROUTE = "/s";
        WEBSITE_TITLE = "xhos's zipline";
        WEBSITE_SHOW_FILES_PER_USER = "true";
        WEBSITE_SHOW_VERSION = "true";
      };
    };
  };
}
