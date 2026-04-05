{
  lib,
  config,
  ...
}: let
  exposedServices = lib.attrValues config.homelab.exposedServices;
  dynamicServicePorts = lib.unique (map (s: s.port) exposedServices);

  lanTcpPorts = [80 443] ++ dynamicServicePorts;

  mkPortSet = ports: "{ ${lib.concatMapStringsSep ", " toString ports} }";

  fw = config.homelab.firewall;
in {
  options.homelab.exposedServices = lib.mkOption {
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
          description = "Whether to expose publicly via proxy-1";
        };
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
    description = "Services exposed on the local network";
  };

  options.homelab.firewall = {
    extraInputRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
    extraForwardRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
    extraPreroutingRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
    extraPostroutingRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
  };

  config = lib.mkIf config.homelab.enable {
    networking = {
      bridges.vmbr0.interfaces = ["enp0s31f6"];
      interfaces.enp0s31f6.useDHCP = false;
      interfaces.vmbr0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = config.homelab.config.homelabLocalIP;
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
              tcp dport 22 accept

              # LAN only (vmbr0)
              iifname vmbr0 ip saddr 10.0.0.0/24 tcp dport ${mkPortSet lanTcpPorts} accept
              iifname vmbr0 ip saddr 10.0.0.0/24 udp dport { 22000 } accept
              iifname vmbr0 ip saddr 10.0.0.0/24 tcp dport { 22000 } accept

              ${fw.extraInputRules}

              # Tailscale
              iifname tailscale0 accept
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
