{
  inputs,
  lib,
  config,
  ...
}: let
  cfg = config.homelab.netboot;
  iface = config.homelab.baremetal.interface;
  nyx =
    (inputs.self.nixosConfigurations.nyx.extendModules {
      modules = [
        {
          disabledModules = ["installer/cd-dvd/installation-cd-minimal.nix"];
          imports = ["${inputs.nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix"];
        }
      ];
    }).config;
in {
  options.homelab.netboot = {
    enable = lib.mkEnableOption "pxe boot the nyx installer on the lan (proxydhcp, the router keeps handing out leases)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8098;
      description = "http port pixiecore serves the kernel/initrd on (80 belongs to caddy)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.pixiecore = {
      enable = true;
      mode = "boot";
      inherit (cfg) port;
      statusPort = cfg.port;
      kernel = "${nyx.system.build.kernel}/${nyx.system.boot.loader.kernelFile}";
      initrd = "${nyx.system.build.netbootRamdisk}/initrd";
      cmdLine = "init=${nyx.system.build.toplevel}/init ${toString nyx.boot.kernelParams}";
    };

    # dhcp discovers come from 0.0.0.0, so no saddr match on 67
    homelab.firewall.extraInputRules = ''
      iifname ${iface} udp dport { 67, 69, 4011 } accept
      iifname ${iface} ip saddr 10.0.0.0/24 tcp dport ${toString cfg.port} accept
    '';
  };
}
