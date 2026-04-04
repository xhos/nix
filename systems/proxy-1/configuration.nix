{
  inputs,
  pkgs,
  config,
  ...
}: let
  arashiIp = "100.64.0.3";

  caddy-l4 = pkgs.caddy.withPlugins {
    plugins = ["github.com/mholt/caddy-l4@v0.0.0-20251124224044-66170bec9f4d"];
    hash = "sha256-wjK4Ym83Rxo6IrkM4V0OAvUb/cgs5udDc/R0IRoZ/f4=";
  };
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];
  headless = true;

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
          type nat hook prerouting priority -100; policy accept;
          tcp dport { 80, 443 } dnat to ${arashiIp}
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
    allowedTCPPorts = [80 443];
    allowedUDPPorts = [config.services.tailscale.port];
  };

  services.caddy = {
    enable = true;
    package = caddy-l4;
    globalConfig = ''
      admin off
      layer4 {
        :443 {
          route {
            proxy {
              proxy_protocol v2
              upstream ${arashiIp}:443
            }
          }
        }
      }
    '';
  };

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./proxy.pub];

  system.stateVersion = "25.11";
}
