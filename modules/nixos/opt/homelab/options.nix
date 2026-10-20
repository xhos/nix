{lib, ...}: {
  options.homelab.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "enable homelab infra";
  };

  options.homelab.config = {
    homelabLocalIP = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0.10";
      description = "homelab's IP on main LAN";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "xhos.dev";
      description = "domain for all services";
    };

    tailnet = {
      owner = lib.mkOption {
        type = lib.types.str;
        default = "xhos";
        description = "headscale user with full access to the tailnet";
      };

      serverTag = lib.mkOption {
        type = lib.types.str;
        default = "tag:server";
        description = "tag homelab hosts join the tailnet with";
      };

      guestTag = lib.mkOption {
        type = lib.types.str;
        default = "tag:guest";
        description = "tag for guest devices, limited to game ports and services marked guest";
      };
    };
  };
}
