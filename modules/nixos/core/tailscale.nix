{config, ...}: {
  sops.secrets."vpn/tailscale" = {};

  persist.dirs = ["var/lib/tailscale"];

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."vpn/tailscale".path;
    extraUpFlags = ["--login-server" "https://hs.xhos.dev"];
  };
}
