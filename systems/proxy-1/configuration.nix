# hosts/proxy-1/default.nix
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
        && cfg.config.homelab.config.tailscaleIP != ""
    )
    inputs.self.nixosConfigurations;

  hostData =
    lib.mapAttrs (hostname: cfg: {
      hostname = hostname;
      services = cfg.config.homelab.exposedServices;
    })
    homelabHosts;

  domain = config.homelab.config.domain;

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

  headless = true;
  homelab.headscale.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "proxy-1";
  networking.hostId = "6e172669";

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.nftables = {
    enable = true;
    tables.nat = {
      family = "ip";
      content = ''
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
    allowedTCPPorts = [80 443];
    allowedUDPPorts = [config.services.tailscale.port 41641];
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
    };
  };

  systemd.services.caddy = {
    after = ["acme-${domain}.service"];
    wants = ["acme-${domain}.service"];
    reloadTriggers = lib.mkForce [];
  };

  services.caddy = {
    enable = true;
    globalConfig = "admin off";

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
