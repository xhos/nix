{
  config,
  inputs,
  ...
}: {
  imports = [inputs.kodama.nixosModules.default];

  sops.secrets = {
    "api/kodama/token" = {};
    "api/kodama/ha" = {};
    "api/kodama/telegram" = {};
    "api/kodama/telegram-user-id" = {};
  };
  sops.templates = {
    "kodama.env".content = ''
      KODAMA_TOKEN=${config.sops.placeholder."api/kodama/token"}
      CLIPROXY_KEY=${config.sops.placeholder."api/kodama/token"}
      HA_TOKEN=${config.sops.placeholder."api/kodama/ha"}
    '';
    "kodama-telegram.env".content = ''
      KODAMA_TOKEN=${config.sops.placeholder."api/kodama/token"}
      TELEGRAM_TOKEN=${config.sops.placeholder."api/kodama/telegram"}
      TELEGRAM_USER_ID=${config.sops.placeholder."api/kodama/telegram-user-id"}
    '';
    "kodama-ha.env".content = ''
      KODAMA_TOKEN=${config.sops.placeholder."api/kodama/token"}
      HA_URL=http://127.0.0.1:8123
      HA_TOKEN=${config.sops.placeholder."api/kodama/ha"}
    '';
  };

  services.kodama = {
    enable = true;
    configFile = ./kodama.toml;
    # the proxy only listens on localhost, so the kodama token doubles as its key
    proxy.enable = true;
    environmentFile = config.sops.templates."kodama.env".path;
    telegram = {
      enable = true;
      environmentFile = config.sops.templates."kodama-telegram.env".path;
    };
    ha = {
      enable = true;
      listen = "127.0.0.1:11435"; # HA is on this box
      environmentFile = config.sops.templates."kodama-ha.env".path;
    };
  };

  # enrai uses its own nftables firewall, which already accepts tailscale0.
  # Its physical LAN interface does not accept port 7777.
  persist.dirs = ["/var/lib/kodama"];
}
