{
  lib,
  config,
  ...
}: let
  # Core infrastructure ports
  coreServicePorts = {
    ssh = 22;
    adguard-dns = 53;
    adguard-web = 9393;
    http = 80;
    https = 443;
    wireguard = 55055;
    syncthing-sync = 22000;
  };

  # Collect dynamically registered services
  exposedServices = lib.attrValues config._enrai.exposedServices;
  dynamicServicePorts = lib.unique (map (s: s.port) exposedServices);

  # Combine core and dynamic ports for LAN-exposed services
  lanTcpPorts =
    [
      coreServicePorts.adguard-web
      coreServicePorts.http
      coreServicePorts.https
    ]
    ++ dynamicServicePorts;

  # Helper to generate nftables set syntax: { port1, port2, port3 }
  mkPortSet = ports: "{ ${lib.concatMapStringsSep ", " toString ports} }";

  fw = config._enrai.firewall;
in {
  # Option for services to self-register for network exposure
  options._enrai.exposedServices = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = "Port the service listens on";
        };
        upstream = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address the service listens on";
        };
        exposed = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to expose via WireGuard tunnel to internet";
        };
        amneziaAccessible = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether Amnezia VPN clients can access this service";
        };
        # Optional overrides (defaults to attribute name)
        name = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Human-readable service name (defaults to attribute name)";
        };
        subdomain = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Subdomain for the service (defaults to attribute name)";
        };
      };
    });
    default = {};
    description = "Services that should be exposed on the local network";
  };

  # Composable firewall rule extension points
  options._enrai.firewall = {
    extraInputRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra nftables input chain rules";
    };
    extraForwardRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra nftables forward chain rules";
    };
    extraPreroutingRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra nftables NAT prerouting rules";
    };
    extraPostroutingRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra nftables NAT postrouting rules";
    };
  };

  config = {
    # Base network infrastructure
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

      defaultGateway = "10.0.0.1";

      firewall.enable = lib.mkForce false;

      nftables = {
        enable = true;

        ruleset = ''
          table inet filter {
            chain input {
              type filter hook input priority filter; policy drop;

              ct state vmap { established : accept, related : accept, invalid : drop }
              iifname lo accept
              ip protocol icmp accept
              ip6 nexthdr icmpv6 accept

              # Global access
              tcp dport ${toString coreServicePorts.ssh} accept
              udp dport ${toString coreServicePorts.wireguard} accept

              # LAN only (vmbr0)
              iifname vmbr0 ip saddr 10.0.0.0/24 tcp dport ${mkPortSet lanTcpPorts} accept
              iifname vmbr0 ip saddr 10.0.0.0/24 udp dport { 53, 22000 } accept
              iifname vmbr0 ip saddr 10.0.0.0/24 tcp dport { 53, 22000 } accept

              ${fw.extraInputRules}

              # WireGuard tunnel
              iifname wg0 accept
            }

            chain forward {
              type filter hook forward priority filter; policy drop;

              ct state vmap { established : accept, related : accept, invalid : drop }

              ${fw.extraForwardRules}
            }

            chain output {
              type filter hook output priority filter; policy accept;
            }
          }

          ${lib.optionalString (fw.extraPreroutingRules != "" || fw.extraPostroutingRules != "") ''
            table ip nat {
              ${lib.optionalString (fw.extraPreroutingRules != "") ''
              chain prerouting {
                type nat hook prerouting priority dstnat; policy accept;

                ${fw.extraPreroutingRules}
              }
            ''}

              ${lib.optionalString (fw.extraPostroutingRules != "") ''
              chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;

                ${fw.extraPostroutingRules}
              }
            ''}
            }
          ''}
        '';
      };
    };
  };
}
