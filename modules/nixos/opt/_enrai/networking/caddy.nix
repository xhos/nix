{
  config,
  lib,
  ...
}: let
  enraiIP = config._enrai.config.enraiLocalIP;
  localDomain = config._enrai.config.localDomain;
  publicDomain = config._enrai.config.publicDomain;

  # Collect all registered services and apply defaults
  exposedServices = lib.mapAttrs (name: svc:
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
    })
  config._enrai.exposedServices;

  # Split services into local-only and public
  localServices = lib.filterAttrs (_: svc: !svc.exposed) exposedServices;
  publicServices = lib.filterAttrs (_: svc: svc.exposed) exposedServices;

  # Generate local vhosts (*.lab.xhos.dev)
  mkLocalVhosts =
    lib.mapAttrs' (
      _: svc:
        lib.nameValuePair "${svc.subdomain}.${localDomain}" {
          useACMEHost = localDomain;
          extraConfig = ''
            bind ${enraiIP}
            reverse_proxy ${svc.upstream}:${toString svc.port}
            @blocked not remote_ip 10.0.0.0/24
            respond @blocked 403
          '';
        }
    )
    localServices;

  # Generate public vhosts (*.xhos.dev via WireGuard)
  mkPublicVhosts =
    lib.mapAttrs' (
      _: svc:
        lib.nameValuePair "${svc.subdomain}.${publicDomain}" {
          useACMEHost = publicDomain;
          listenAddresses = [config._enrai.config.tunnelIP];
          extraConfig = ''
            reverse_proxy 127.0.0.1:${toString svc.port}
          '';
        }
    )
    publicServices;

  allVhosts = mkLocalVhosts // mkPublicVhosts;
in {
  sops.secrets."api/cloudflare" = {};

  security.acme = {
    acceptTerms = true;
    defaults.email = "lets-encrypt@xhos.dev";

    # Wildcard cert for local services
    certs.${localDomain} = {
      group = config.services.caddy.group;
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      domain = "*.${localDomain}";
      extraDomainNames = [localDomain];
      environmentFile = config.sops.secrets."api/cloudflare".path;
    };

    # Wildcard cert for public services
    certs.${publicDomain} = {
      group = config.services.caddy.group;
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      domain = "*.${publicDomain}";
      extraDomainNames = [publicDomain];
      environmentFile = config.sops.secrets."api/cloudflare".path;
    };
  };

  # Ensure Caddy waits for certs and reloads gracefully
  systemd.services.caddy = {
    after = ["acme-${localDomain}.service" "acme-${publicDomain}.service"];
    wants = ["acme-${localDomain}.service" "acme-${publicDomain}.service"];
    reloadTriggers = lib.mkForce [];
  };

  services.caddy = {
    enable = true;
    email = "lets-encrypt@xhos.dev";

    globalConfig = ''
      admin off
      servers ${config._enrai.config.tunnelIP}:443 {
        listener_wrappers {
          proxy_protocol {
            timeout 5s
            allow 10.100.0.0/24
          }
          tls
        }
      }
    '';

    virtualHosts = allVhosts;
  };
}
