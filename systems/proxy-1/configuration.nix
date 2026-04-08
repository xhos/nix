{
  inputs,
  config,
  lib,
  ...
}: let
  arashiIp = "100.64.0.1";
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
    certs."xhos.dev" = {
      group = config.services.caddy.group;
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      domain = "*.xhos.dev";
      extraDomainNames = ["xhos.dev"];
      environmentFile = config.sops.secrets."api/cloudflare".path;
    };
  };

  systemd.services.caddy = {
    after = ["acme-xhos.dev.service"];
    wants = ["acme-xhos.dev.service"];
    reloadTriggers = lib.mkForce [];
  };

  services.caddy = {
    enable = true;
    globalConfig = "admin off";

    virtualHosts."hs.xhos.dev" = {
      useACMEHost = "xhos.dev";
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.headscale.port}
      '';
    };

    # catch-all for other public services — forward to arashi
    virtualHosts."*.xhos.dev" = {
      useACMEHost = "xhos.dev";
      extraConfig = ''
        reverse_proxy ${arashiIp}:80
      '';
    };
  };

  systemd.services.tailscaled-autoconnect = {
    after = ["headscale.service" "caddy.service"];
    requires = ["headscale.service" "caddy.service"];
  };

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./proxy.pub];

  system.stateVersion = "25.11";
}
