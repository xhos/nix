{lib, ...}: {
  options._enrai.config = {
    enraiLocalIP = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0.10";
      description = "Enrai's IP on main LAN";
    };

    tunnelIP = lib.mkOption {
      type = lib.types.str;
      default = "10.100.0.10";
      description = "Enrai's IP on WireGuard tunnel";
    };

    localDomain = lib.mkOption {
      type = lib.types.str;
      default = "lab.xhos.dev";
      description = "Domain for local services";
    };

    publicDomain = lib.mkOption {
      type = lib.types.str;
      default = "xhos.dev";
      description = "Domain for public services";
    };

    vmNetwork = lib.mkOption {
      type = lib.types.str;
      default = "192.168.100";
      description = "VM subnet prefix";
    };
  };
}
