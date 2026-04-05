{
  config,
  pkgs,
  lib,
  ...
}: {
  options.homelab.tg-notify = {
    enable = lib.mkEnableOption "telegram notification script";
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "tg-notify package for use in other modules";
    };
  };

  config = lib.mkIf config.homelab.tg-notify.enable {
    homelab.tg-notify.package = pkgs.writeShellApplication {
      name = "tg-notify";
      runtimeInputs = [pkgs.curl pkgs.jq];
      text = ''
        # shellcheck disable=SC1091
        source ${config.sops.secrets."env/tg-notify".path}

        if [ $# -eq 0 ]; then
          echo "Usage: tg-notify <message>" >&2
          exit 1
        fi
        message="$*"
        response=$(curl -s -X POST \
          "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
          -d chat_id="$TELEGRAM_CHAT_ID" \
          -d text="$message" \
          -d parse_mode="HTML")
        if echo "$response" | jq -e '.ok' >/dev/null; then
          exit 0
        else
          echo "failed to send notification" >&2
          echo "$response" | jq -r '.description' >&2
          exit 1
        fi
      '';
    };
    environment.systemPackages = [config.homelab.tg-notify.package];
    sops.secrets."env/tg-notify" = {
      mode = "0444";
    };
  };
}
