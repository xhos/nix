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
  extraDomains = domain: exposed:
    lib.filter (d: d != null) (lib.mapAttrsToList (
        _: svc:
          if svc.exposed == exposed && lib.hasInfix "." svc.subdomain
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

  mkPublicVhosts =
    lib.mapAttrs' (
      _: svc:
        lib.nameValuePair "${svc.subdomain}.${publicDomain}" {
          useACMEHost = publicDomain;
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
    "*.${publicDomain}" = {
      useACMEHost = publicDomain;
      extraConfig = "respond 404 { close }";
    };
  };
in {
  config = lib.mkIf config.homelab.enable {
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
        extraDomainNames = [localDomain] ++ extraDomains localDomain false;
        environmentFile = config.sops.secrets."api/cloudflare".path;
      };
      certs.${publicDomain} = {
        group = config.services.caddy.group;
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        domain = "*.${publicDomain}";
        extraDomainNames = [publicDomain] ++ extraDomains publicDomain true;
        environmentFile = config.sops.secrets."api/cloudflare".path;
      };
    };

    systemd.services.caddy = {
      after = ["acme-${localDomain}.service" "acme-${publicDomain}.service"];
      wants = ["acme-${localDomain}.service" "acme-${publicDomain}.service"];
      reloadTriggers = lib.mkForce [];
    };

    services.caddy = {
      enable = true;
      email = "lets-encrypt@xhos.dev";

      # PROXY protocol for public services coming through proxy-1
      globalConfig = ''
        admin off
        servers :443 {
          listener_wrappers {
            proxy_protocol {
              timeout 5s
              allow 100.64.0.0/10
            }
            tls
          }
        }
      '';

      virtualHosts = mkLocalVhosts // mkPublicVhosts // catchAlls;
    };
  };
}
