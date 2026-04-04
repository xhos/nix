{config, ...}: {
  sops.secrets."vpn/tailscale" = {};

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."vpn/tailscale".path;
    extraUpFlags = ["--login-server" "https://hs.xhos.dev"];
  };
}
