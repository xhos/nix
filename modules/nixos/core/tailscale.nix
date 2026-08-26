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
