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

    tailscaleIP = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "tailscale IP of this node (used for headscale extra_records)";
    };
  };
}
