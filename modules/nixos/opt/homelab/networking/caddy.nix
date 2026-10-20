{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = config.homelab.config.domain;
  gatePort = 9180;

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
          # tailnet clients other than the owner and servers (i.e. guests) are
          # refused unless the service opts in. lan and localhost aren't checked
          extraConfig =
            lib.optionalString (!svc.guest) ''
              @tailnet remote_ip 100.64.0.0/10
              forward_auth @tailnet 127.0.0.1:${toString gatePort} {
                uri /
                header_up Remote-Addr {remote_host}
                header_up Remote-Port {remote_port}
              }
            ''
            + ''
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
      extraConfig = "respond 404";
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
        # ari breaks renewal of long-expired certs
        extraLegoRenewFlags = ["--ari-disable"];
      };
    };

    systemd.services.caddy = {
      after = ["acme-${domain}.service"];
      wants = ["acme-${domain}.service"];
    };

    systemd.services.tailnet-gate = {
      description = "tailnet identity check for caddy forward_auth";
      wantedBy = ["caddy.service"];
      before = ["caddy.service"];
      after = ["tailscaled.service"];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./tailnet-gate.py} ${toString gatePort} ${config.homelab.config.tailnet.owner} ${config.homelab.config.tailnet.serverTag}";
        DynamicUser = true;
        Restart = "always";
      };
    };

    services.caddy = {
      enable = true;
      email = "lets-encrypt@xhos.dev";

      # no `admin off`, caddy reload needs it for acme
      virtualHosts = mkLocalVhosts // mkPublicVhosts // catchAlls;
    };
  };
}
