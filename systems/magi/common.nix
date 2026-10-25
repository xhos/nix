# shared config for the magi cluster: three dell optiplex 5040s (melchior, balthasar, casper)
{
  config,
  inputs,
  ...
}: let
  ips = {
    melchior = "10.0.0.15";
    balthasar = "10.0.0.16";
    casper = "10.0.0.17";
  };
  ip = ips.${config.networking.hostName};
in {
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disko.nix {})
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  profile = "minimal";
  homelab.forgejo-runner.enable = true;

  # stable nic name
  systemd.network.links."10-lan0" = {
    matchConfig = {
      Type = "ether";
      Path = "pci-*";
    };
    linkConfig.Name = "lan0";
  };

  networking = {
    defaultGateway = "10.0.0.1";
    interfaces.lan0.ipv4.addresses = [
      {
        address = ip;
        prefixLength = 24;
      }
    ];

    firewall = {
      trustedInterfaces = ["cni0" "flannel.1"];
      interfaces.tailscale0.allowedTCPPorts = [80 6443]; # proxy-1 -> traefik, kubectl from tailnet
      extraCommands = "iptables -A nixos-fw -i lan0 -m iprange --src-range 10.0.0.15-10.0.0.17 -j nixos-fw-accept"; # magi nodes trust each other fully
    };
  };

  security.sudo.wheelNeedsPassword = false; # for deploy-rs to work nicely
  services.fail2ban.ignoreIP = ["10.0.0.0/24" "100.64.0.0/10"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  system.stateVersion = "26.11";

  sops.secrets."k3s/token" = {};
  persist.dirs = ["/var/lib/rancher/k3s"];

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets."k3s/token".path;
    extraFlags = [
      "--node-ip=${ip}"
      "--flannel-iface=lan0"
      "--tls-san=${config.networking.hostName}.ts.xhos.dev"
    ];
  };
}
