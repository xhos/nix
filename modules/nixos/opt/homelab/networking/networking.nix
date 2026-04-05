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
  cfg = config.homelab;
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
    description = "Services exposed on the network";
  };

  options.homelab.baremetal = {
    enable = lib.mkEnableOption "baremetal networking";
    interface = lib.mkOption {
      type = lib.types.str;
      default = "enp0s31f6";
      description = "Physical NIC";
    };
    gateway = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0.1";
    };
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

  config = lib.mkIf cfg.enable {
    networking = lib.mkMerge [
      (lib.mkIf cfg.baremetal.enable {
        interfaces.${cfg.baremetal.interface} = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = cfg.config.homelabLocalIP;
              prefixLength = 24;
            }
          ];
        };
        defaultGateway = cfg.baremetal.gateway;
      })

      {
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

                tcp dport 22 accept

                ${lib.optionalString cfg.baremetal.enable ''
              iifname ${cfg.baremetal.interface} ip saddr 10.0.0.0/24 tcp dport ${mkPortSet lanTcpPorts} accept
              iifname ${cfg.baremetal.interface} ip saddr 10.0.0.0/24 udp dport { 22000 } accept
              iifname ${cfg.baremetal.interface} ip saddr 10.0.0.0/24 tcp dport { 22000 } accept
            ''}

                ${fw.extraInputRules}

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
      }
    ];
  };
}
