# headscale.nix
{
  config,
  lib,
  inputs,
  ...
}: {
  options.homelab.headscale.enable = lib.mkEnableOption "run headscale control plane (should be one of these in the network)";

  config = lib.mkIf config.homelab.headscale.enable (let
    domain = config.homelab.config.domain;
  in {
    homelab.exposedServices.headscale = {
      port = 8080;
      subdomain = "hs";
      exposed = true;
    };

    sops.secrets."vpn/headscale-identity".owner = config.services.headscale.user;

    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8080;
      settings = {
        noise.private_key_path = config.sops.secrets."vpn/headscale-identity".path;
        server_url = "https://hs.${domain}";
        ip_prefixes = ["100.64.0.0/10"];
        dns = {
          magic_dns = true;
          base_domain = "ts.${domain}";
          nameservers.global = ["1.1.1.1" "1.0.0.1"];

          extra_records = let
            homelabHosts =
              lib.filterAttrs (
                name: cfg:
                  name
                  != "proxy-1"
                  && (cfg.config.homelab.enable or false)
                  && cfg.config.homelab.config.tailscaleIP != ""
              )
              inputs.self.nixosConfigurations;
          in
            lib.flatten (lib.mapAttrsToList (
                _: cfg: let
                  localSvcs = lib.filterAttrs (_: s: !s.exposed) cfg.config.homelab.exposedServices;
                  tailscaleIP = cfg.config.homelab.config.tailscaleIP;
                in
                  lib.mapAttrsToList (svcName: svc: {
                    name = "${
                      if svc.subdomain != ""
                      then svc.subdomain
                      else svcName
                    }.${domain}";
                    type = "A";
                    value = tailscaleIP;
                  })
                  localSvcs
              )
              homelabHosts);
        };
      };
    };
  });
}
