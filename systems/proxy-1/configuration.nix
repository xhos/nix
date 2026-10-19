{
  inputs,
  config,
  lib,
  ...
}: let
  homelabHosts =
    lib.filterAttrs (
      name: cfg:
        name
        != "proxy-1"
        && (cfg.config.homelab.enable or false)
    )
    inputs.self.nixosConfigurations;

  hostData =
    lib.mapAttrs (hostname: cfg: {
      hostname = hostname;
      services = cfg.config.homelab.exposedServices;
      tcpForwards = cfg.config.homelab.tcpForwards;
    })
    homelabHosts;

  domain = config.homelab.config.domain;

  # collect all TCP/UDP forwards across hosts -> nginx stream relays
  allForwards = lib.flatten (lib.mapAttrsToList (
      _: host:
        lib.mapAttrsToList (
          _: fwd: {
            inherit (fwd) listen port proto;
            target = "${host.hostname}.ts.${domain}";
          }
        )
        host.tcpForwards
    )
    hostData);

  # relayed by name instead of dnat so nothing here needs a tailnet ip.
  # dnat bought nothing anyway, tailscale0 egress was masqueraded
  streamServers =
    lib.concatMapStrings (fwd: ''
      server {
        listen ${toString fwd.listen}${lib.optionalString (fwd.proto == "udp") " udp"};
        set $target ${fwd.target}:${toString fwd.port};
        proxy_pass $target;
      }
    '')
    allForwards;

  forwardPublicPorts =
    map (fwd: {
      inherit (fwd) proto;
      port = fwd.listen;
    })
    allForwards;

  autoVhosts = lib.mkMerge (lib.mapAttrsToList (
      _: host:
        lib.mapAttrs' (
          svcName: svc:
            lib.nameValuePair "${
              if svc.subdomain != ""
              then svc.subdomain
              else svcName
            }.${domain}" {
              useACMEHost = domain;
              extraConfig = ''
                reverse_proxy ${host.hostname}.ts.${domain}:80
              '';
            }
        ) (lib.filterAttrs (_: s: s.exposed && s.subdomain != "hs") host.services)
    )
    hostData);
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  profile = "minimal";
  homelab.headscale.enable = true;
  homelab.reality-vpn.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "proxy-1";
  networking.hostId = "6e172669";

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.nftables = {
    enable = true;
    tables.nat = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          iifname "ens3" udp dport 443 counter redirect to :8443
        }

        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname "tailscale0" masquerade
          iifname "tailscale0" oifname "ens3" masquerade
        }
      '';
    };
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedTCPPorts =
      [80 443]
      ++ (map (f: f.port) (lib.filter (f: f.proto == "tcp") forwardPublicPorts));
    allowedUDPPorts =
      [443 config.services.tailscale.port 41641]
      ++ (map (f: f.port) (lib.filter (f: f.proto == "udp") forwardPublicPorts));
  };

  # caddy owns 80/443, nginx is only here for raw tcp/udp
  services.nginx = {
    enable = true;
    virtualHosts = {}; # drop the default localhost vhost, it'd grab :80
    streamConfig = ''
      # quad100, re-resolved so a host changing ip doesn't need a reload
      resolver 100.100.100.100 valid=60s;
      ${streamServers}
    '';
  };
  systemd.services.nginx = {
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
  };

  sops.secrets."api/cloudflare" = {};

  security.acme = {
    acceptTerms = true;
    defaults.email = "lets-encrypt@xhos.dev";
    certs.${domain} = {
      group = config.services.caddy.group;
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      domain = "*.${domain}";
      extraDomainNames = [domain];
      environmentFile = config.sops.secrets."api/cloudflare".path;
      extraLegoRenewFlags = ["--ari-disable"];
    };
  };

  systemd.services.caddy = {
    after = ["acme-${domain}.service"];
    wants = ["acme-${domain}.service"];
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      https_port 8443
    '';

    virtualHosts = lib.mkMerge [
      autoVhosts
      {
        "hs.${domain}" = {
          useACMEHost = domain;
          extraConfig = ''
            reverse_proxy 127.0.0.1:${toString config.services.headscale.port}
          '';
        };
        "*.${domain}" = {
          useACMEHost = domain;
          extraConfig = "respond 404";
        };
      }
    ];
  };

  systemd.services.tailscaled-autoconnect = {
    after = ["headscale.service" "caddy.service"];
    requires = ["headscale.service" "caddy.service"];
  };

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./proxy.pub];

  system.stateVersion = "25.11";
}
