{
  lib,
  config,
  ...
}: let
  vmNetwork = "192.168.100";
  mcIp = "${vmNetwork}.20";
  amneziaIp = "${vmNetwork}.21";

  # Core infrastructure ports
  coreServicePorts = {
    ssh = 10022;
    proxmox = 8006;
    adguard-dns = 53;
    adguard-web = 9393;
    http = 80;
    https = 443;
    wireguard = 55055;
    dhcp-server = 67;
    dhcp-client = 68;
    syncthing-sync = 22000;
  };

  # Collect dynamically registered services
  exposedServices = lib.attrValues config._enrai.exposedServices;
  dynamicServicePorts = lib.unique (map (s: s.port) exposedServices);

  # Services accessible from Amnezia VPN
  amneziaAccessibleServices = lib.filter (s: s.amneziaAccessible) exposedServices;
  amneziaServicePorts = lib.unique (map (s: s.port) amneziaAccessibleServices);

  # Combine core and dynamic ports for LAN-exposed services
  lanTcpPorts =
    [
      coreServicePorts.proxmox
      coreServicePorts.adguard-web
      coreServicePorts.http
      coreServicePorts.https
    ]
    ++ dynamicServicePorts;

  # Helper to generate nftables set syntax: { port1, port2, port3 }
  mkPortSet = ports: "{ ${lib.concatMapStringsSep ", " toString ports} }";
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

  config = {
    networking.firewall.enable = lib.mkForce false;

    networking.nftables = {
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

            # VMs only need DHCP (vmbr1)
            iifname vmbr1 udp dport 67 accept

            # Amnezia VPN clients can access specific services
            ${lib.optionalString (amneziaServicePorts != []) ''
          iifname vmbr1 ip saddr ${amneziaIp} tcp dport ${mkPortSet amneziaServicePorts} accept
        ''}

            # WireGuard tunnel
            iifname wg0 accept
          }

          chain forward {
            type filter hook forward priority filter; policy drop;

            ct state vmap { established : accept, related : accept, invalid : drop }

            # VMs can reach internet, not LAN
            iifname vmbr1 oifname vmbr0 ip daddr 10.0.0.0/24 drop
            iifname vmbr1 oifname vmbr0 accept

            # Port forwards to VMs
            ip daddr 192.168.100.0/24 accept
          }

          chain output {
            type filter hook output priority filter; policy accept;
          }
        }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;

            # Direct access from router (bypasses VPS tunnel)
            iifname vmbr0 tcp dport 25565 dnat to ${mcIp}:25565

            # WireGuard tunnel forwards
            iifname wg0 tcp dport 2222 dnat to ${mcIp}:22
            iifname wg0 tcp dport 2223 dnat to ${amneziaIp}:22
            iifname wg0 tcp dport 25565 dnat to ${mcIp}:25565
            iifname wg0 tcp dport 35000-35006 dnat to ${amneziaIp}
            iifname wg0 udp dport 35000-35006 dnat to ${amneziaIp}
          }

          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;

            oifname vmbr0 ip saddr 192.168.100.0/24 masquerade
          }
        }
      '';
    };

    # DNS configuration for enrai itself
    services.resolved.extraConfig = lib.mkForce ''
      DNSStubListener=no
    '';

    # Use local AdGuard first, fallback to public DNS if it fails
    networking.nameservers = lib.mkForce ["127.0.0.1" "1.1.1.1"];
  };
}
