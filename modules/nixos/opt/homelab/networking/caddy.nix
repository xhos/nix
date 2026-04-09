{
  config,
  lib,
  ...
}: let
  domain = config.homelab.config.domain;

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
        lib.nameValuePair "${svc.subdomain}.${domain}" {
          useACMEHost = domain;
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
        lib.nameValuePair "http://${svc.subdomain}.${domain}" {
          extraConfig = ''
            reverse_proxy ${svc.upstream}:${toString svc.port} {
              header_up X-Forwarded-Proto https
            }
          '';
        }
    )
    publicServices;

  catchAlls = {
    "*.${domain}" = {
      useACMEHost = domain;
      extraConfig = "respond 404 { close }";
    };
  };
in {
  config = lib.mkIf config.homelab.enable {
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
        extraDomainNames = [domain] ++ extraDomains domain;
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
      email = "lets-encrypt@xhos.dev";

      globalConfig = ''
        admin off
      '';

      virtualHosts = mkLocalVhosts // mkPublicVhosts // catchAlls;
    };
  };
}
