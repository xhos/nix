# everything that only works from inside the tailnet. core modules default to
# public endpoints, so a host that doesn't import this still works, just slower
{
  flake.modules.nixos.tailnet = {
    config,
    lib,
    ...
  }: let
    # homelab hosts join with a tag:server key, so they
    # don't belong to the owner user and guest acls can target them
    server = config.homelab.enable || config.homelab.headscale.enable;
    key =
      if server
      then "vpn/tailscale-server"
      else "vpn/tailscale";
  in {
    sops.secrets.${key} = {};

    persist.dirs = ["/var/lib/tailscale"];

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.${key}.path;
      extraUpFlags = ["--login-server" "https://hs.xhos.dev"];
    };

    # chromium prefers tailscale0 over wifi for webrtc, so discord voice packets
    # leave via wlan0 with a tailnet source ip the router can't reply to. masquerade fixes it.
    networking.firewall = lib.mkIf (config.headless != true) rec {
      extraCommands = "iptables -t nat -A POSTROUTING -s 100.64.0.0/10 ! -d 100.64.0.0/10 ! -o lo -j MASQUERADE";
      extraStopCommands = builtins.replaceStrings ["-A POSTROUTING"] ["-D POSTROUTING"] extraCommands + " || true";
    };

    systemd.services.tailscaled-autoconnect = {
      wantedBy = lib.mkForce [];
      startLimitIntervalSec = 0;
      serviceConfig = {
        TimeoutStartSec = "3min";
        Restart = "on-failure";
        RestartSec = "20s";
      };
    };
    systemd.services.tailscaled.wants = ["tailscaled-autoconnect.service"];

    # magi binary cache, ahead of the public ones
    nix.settings.substituters = lib.mkBefore [
      "http://melchior.ts.xhos.dev:3902"
      "http://balthasar.ts.xhos.dev:3902"
      "http://casper.ts.xhos.dev:3902"
    ];

    # forgejo's sshd only listens here; key auth instead of the https token
    forge.remote = "ssh://git@enrai.ts.xhos.dev:2222/xhos/";
  };
}
