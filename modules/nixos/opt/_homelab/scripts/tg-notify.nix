{
  config,
  pkgs,
  ...
}: {
  sops.secrets."env/tg-notify" = {};

  environment.systemPackages = with pkgs; [
    # tg-notify is a simple script that hits a predetermined chat
    # with myself on telegram with a notification, via a bot
    (writeShellApplication {
      name = "tg-notify";
      runtimeInputs = [curl jq];

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
    })
  ];
}
