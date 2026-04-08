{
  config,
  lib,
  ...
}: {
  options.homelab.headscale.enable = lib.mkEnableOption "run headscale control plane (should be one of these in the network)";

  config = lib.mkIf config.homelab.headscale.enable {
    homelab.exposedServices.headscale = {
      port = 8080;
      subdomain = "hs";
      exposed = true;
    };

    sops.secrets."vpn/headscale-identity".owner = config.services.headscale.user;

    # on homelab hosts, exposedServices handles the Caddy vhost via caddy.nix
    # on non-homelab hosts (e.g. proxy-1), add a direct vhost for TLS termination
    services.caddy.virtualHosts."hs.xhos.dev" = lib.mkIf (!config.homelab.enable) {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.headscale.port}
      '';
    };

    services.tailscale.extraUpFlags = ["--login-server" "http://127.0.0.1:8080"];

    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8080;
      settings = {
        noise.private_key_path = config.sops.secrets."vpn/headscale-identity".path;
        server_url = "https://hs.xhos.dev";
        ip_prefixes = ["100.64.0.0/10"];
        dns = {
          magic_dns = true;
          base_domain = "lab.xhos.dev";
          nameservers.global = ["1.1.1.1" "1.0.0.1"];
        };
      };
    };
  };
}
