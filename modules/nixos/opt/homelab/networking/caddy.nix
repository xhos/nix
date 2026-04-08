{
  config,
  lib,
  ...
}: let
  localDomain = config.homelab.config.localDomain;
  publicDomain = config.homelab.config.publicDomain;

  services =
    lib.mapAttrs (
      name: svc:
        svc
        // {
          name =
            if svc.name != ""
            then svc.name
            else name;
          subdomain =
            if svc.subdomain != ""
            then svc.subdomain
            else name;
        }
    )
    config.homelab.exposedServices;

  localServices = lib.filterAttrs (_: svc: !svc.exposed) services;
  publicServices = lib.filterAttrs (_: svc: svc.exposed) services;

  # DNS-01 needs explicit entries for multi-level subdomains e.g. api.null
  # since they aren't covered by the wildcard
  extraDomains = domain:
    lib.filter (d: d != null) (lib.mapAttrsToList (
        _: svc:
          if !svc.exposed && lib.hasInfix "." svc.subdomain
          then "${svc.subdomain}.${domain}"
          else null
      )
      services);

  mkLocalVhosts =
    lib.mapAttrs' (
      _: svc:
        lib.nameValuePair "${svc.subdomain}.${localDomain}" {
          useACMEHost = localDomain;
          extraConfig = ''
            reverse_proxy ${svc.upstream}:${toString svc.port}
          '';
        }
    )
    localServices;

  # public services served over plain HTTP (TLS terminated at proxy-1)
  mkPublicVhosts =
    lib.mapAttrs' (
      _: svc:
        lib.nameValuePair "http://${svc.subdomain}.${publicDomain}" {
          extraConfig = ''
            reverse_proxy ${svc.upstream}:${toString svc.port}
          '';
        }
    )
    publicServices;

  catchAlls = {
    "*.${localDomain}" = {
      useACMEHost = localDomain;
      extraConfig = "respond 404 { close }";
    };
  };
  tailscaleIP = config.homelab.config.tailscaleIP;
in {
  config = lib.mkIf config.homelab.enable {
    services.headscale.settings.dns.extra_records = lib.mkIf (
      config.services.headscale.enable && tailscaleIP != ""
    ) (lib.mapAttrsToList (_: svc: {
      name = "${svc.subdomain}.${localDomain}";
      type = "A";
      value = tailscaleIP;
    }) localServices);

    sops.secrets."api/cloudflare" = {};

    security.acme = {
      acceptTerms = true;
      defaults.email = "lets-encrypt@xhos.dev";
      certs.${localDomain} = {
        group = config.services.caddy.group;
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        domain = "*.${localDomain}";
        extraDomainNames = [localDomain] ++ extraDomains localDomain;
        environmentFile = config.sops.secrets."api/cloudflare".path;
      };
    };

    systemd.services.caddy = {
      after = ["acme-${localDomain}.service"];
      wants = ["acme-${localDomain}.service"];
      reloadTriggers = lib.mkForce [];
    };

    services.caddy = {
      enable = true;
      email = "lets-encrypt@xhos.dev";

      globalConfig = ''
        admin off
      '';

      virtualHosts = mkLocalVhosts // mkPublicVhosts // catchAlls;
    };
  };
}
