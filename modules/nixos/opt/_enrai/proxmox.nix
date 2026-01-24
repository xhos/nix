{
  inputs,
  config,
  ...
}: let
  vmNetwork = "192.168.100";
  amneziaIp = "${vmNetwork}.21";
  mcIp = "${vmNetwork}.20";
in {
  nixpkgs.overlays = [inputs.proxmox-nixos.overlays."x86_64-linux"];
  fileSystems."/var/lib/vz" = {
    device = "/storage/vz";
    options = ["bind"];
  };
  networking = {
    bridges.vmbr0.interfaces = ["enp0s31f6"];
    interfaces.enp0s31f6.useDHCP = false;

    interfaces.vmbr0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = config._enrai.config.enraiLocalIP;
          prefixLength = 24;
        }
      ];
    };

    # Air-gapped VM bridge
    bridges.vmbr1.interfaces = [];
    interfaces.vmbr1 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "${vmNetwork}.1";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = "10.0.0.1";
  };

  systemd.services.dnsmasq = {
    after = ["sys-devices-virtual-net-vmbr1.device"];
    bindsTo = ["sys-devices-virtual-net-vmbr1.device"];
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "vmbr1";
      bind-interfaces = true;
      port = 0; # disable DNS, only DHCP

      dhcp-range = "${vmNetwork}.20,${vmNetwork}.50,24h";
      dhcp-option = [
        "3,${vmNetwork}.1"
        "6,1.1.1.1,8.8.8.8"
      ];
      dhcp-host = [
        "BC:24:11:18:FA:6B,${mcIp}"
        "BC:24:11:1F:12:A5,${amneziaIp}"
      ];
    };
  };

  _enrai.exposedServices.proxmox.port = 8006;

  services.proxmox-ve = {
    enable = true;
    ipAddress = config._enrai.config.enraiLocalIP;
    bridges = [
      "vmbr0"
      "vmbr1"
    ];
  };
}
