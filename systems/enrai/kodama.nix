{config, ...}: {
  sops.secrets = {
    "api/kodama/token" = {};
    "api/kodama/ha" = {};
    "api/kodama/telegram" = {};
    "api/kodama/telegram-user-id" = {};
  };
  sops.templates = {
    "kodama.env".content = ''
      KODAMA_TOKEN=${config.sops.placeholder."api/kodama/token"}
      CLIPROXY_KEY=${config.sops.placeholder."api/cliproxy/kodama"}
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

  persist.dirs = ["/var/lib/kodama"];

  systemd.tmpfiles.rules = ["d /var/lib/kodama-journal 2770 kodama users -"];
  systemd.services.kodama.serviceConfig.ReadWritePaths = ["/var/lib/kodama-journal"];

  systemd.paths.kodama-journal = {
    wantedBy = ["paths.target"];
    pathConfig.DirectoryNotEmpty = "/var/lib/kodama-journal";
  };
  systemd.services.kodama-journal = {
    description = "move kodama journal entries into the daily notes";
    serviceConfig = {
      Type = "oneshot";
      User = "xhos";
      Group = "users";
    };
    script = ''
      set -eu
      inbox=/var/lib/kodama-journal
      notes="/home/xhos/Documents/notes/personal/notes/Daily notes"
      shopt -s nullglob
      for f in "$inbox"/*.md; do mv "$f" "$f.taking"; done
      sleep 1
      for t in "$inbox"/*.md.taking; do
        dest="$notes/$(basename "$t" .taking)"
        if [ -s "$dest" ]; then printf '\n\n' >> "$dest"; fi
        cat "$t" >> "$dest"
        rm "$t"
      done
    '';
  };
}
