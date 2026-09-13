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

  # Chromium classifies any interface the kernel doesn't expose as wireless as Ethernet
  # (network-cost 0), so tailscale0 outranks wlan0 (cost 10) and WebRTC binds the tailnet
  # socket for Discord voice. Those packets still egress wlan0 but carry 100.64.0.35 as
  # their source, which the router won't route a reply to -- voice hangs forever at
  # "DTLS Connecting". Masquerade them to the real egress address. Renaming the interface
  # does not help: Chromium ignores the tun/ipsec name prefixes that stock libwebrtc uses.
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
