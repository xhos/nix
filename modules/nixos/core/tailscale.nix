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

  # tailscaled-autoconnect loops until tailscale is Running; offline it hangs
  # for its 90s start timeout, and multi-user.target (thus graphical.target,
  # which uwsm waits on) is implicitly ordered after its wanted units. Pull it
  # in from tailscaled instead so boot never waits on it.
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [];
  systemd.services.tailscaled.wants = ["tailscaled-autoconnect.service"];
}
