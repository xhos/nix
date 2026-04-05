{lib, ...}: {
  options.homelab.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "enable homelab infra";
  };

  options.homelab.config = {
    homelabLocalIP = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0.10";
      description = "homelab's IP on main LAN";
    };

    localDomain = lib.mkOption {
      type = lib.types.str;
      default = "lab.xhos.dev";
      description = "domain for local services";
    };

    publicDomain = lib.mkOption {
      type = lib.types.str;
      default = "xhos.dev";
      description = "domain for public services";
    };
  };
}
