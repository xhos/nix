{
  config,
  lib,
  ...
}: {
  sops.secrets."vpn/tailscale" = {};

  persist.dirs = ["var/lib/tailscale"];

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."vpn/tailscale".path;
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
}
