{
  config,
  lib,
  ...
}: {
  programs.zsh = lib.mkIf (config.shell == "zsh") {
    shellAliases = {
      v = "nvim";
      ze = "zellij";

      ns = "nix-shell -p";
      ff = "fastfetch";
      gcl = "git clone";
      ga = "git add .";
      gp = "git push";
      gc = "git commit -m";
      lg = "lazygit";
      g = "git";
      s = "nix search nixpkgs";
      nhs = "nh home switch";
      nos = "nh os switch";
      img = "swayimg";
      go-cp-all = "find cmd/ internal/ -name \"*.go\" -exec sh -c 'echo \"--- {} ---\"; cat \"{}\"' \\; | wl-copy";
      b64 = "openssl rand -base64 64 | tr -d '\n' | tr -- '+/' '-_' | tr -d '\n=' | wl-copy";
      clwd = "nix run github:numtide/llm-agents.nix#claude-code --accept-flake-config";
      cdx = "nix run github:numtide/llm-agents.nix#codex --accept-flake-config";
      cplt = "nix run github:numtide/llm-agents.nix#copilot-cli --accept-flake-config";

      nimp = "sudo ncdu -x /";

      u = "uwsm-app --";
    };

    initContent = ''
      imp() {
        sudo fd \
          --one-file-system \
          --base-directory / \
          --type f \
          --hidden \
          --exclude tmp \
          --exclude "etc/passwd" \
          --exclude "home/xhos/.cache" \
          --exclude "home/xhos/.cargo" \
          --exclude "home/xhos/go" \
          --exclude "home/xhos/.local/share/atuin" \
          --exclude "home/xhos/.config/wakatime" \
          --exclude "var/log" \
          --exclude "var/lib/systemd/coredump"
      }

      # deploy-rs: no args deploys every node, otherwise just the named ones
      # on failure, dumps the journal of whatever units failed on that node
      dep() {
        local log=$(mktemp)
        if [[ $# -eq 0 ]]; then
          nix run --inputs-from "$NH_FLAKE" deploy-rs -- "$NH_FLAKE" 2>&1 | tee "$log"
        else
          nix run --inputs-from "$NH_FLAKE" deploy-rs -- --targets "''${@/#/$NH_FLAKE#}" 2>&1 | tee "$log"
        fi
        local rc=''${pipestatus[1]}

        if (( rc != 0 )); then
          local node=$(grep -oP 'Deployment to node \K\S+(?= failed)' "$log" | tail -1)
          local units=$(grep -oP 'the following units failed: \K.*' "$log" | tail -1 | tr -d ',')
          for u in ''${=units}; do
            print -P "\n%F{red}--- $node: $u%f"
            ssh "$node" journalctl -u "$u" --no-pager -n 25 -o cat
          done
        fi

        rm -f "$log"
        return $rc
      }

      try() {
        nix run nixpkgs#$1 -- "''${@:2}"
      }

      togif() {
        local fps=15
        local input

        if [[ $# -eq 2 ]]; then
          fps="$1"
          input="$2"
        else
          input="$1"
        fi

        local output="''${input%.*}.gif"
        local palette="/tmp/palette.png"
        ffmpeg -i "$input" -vf "fps=''${fps},scale=960:-1:flags=lanczos,palettegen" -frames:v 1 -y "$palette" && \
        ffmpeg -i "$input" -i "$palette" -filter_complex "fps=''${fps},scale=960:-1:flags=lanczos[x];[x][1:v]paletteuse" -y "$output"
      }

      fcut() {
        local input="$1"
        local seconds="$2"
        local output="''${input%.*}_cut.''${input##*.}"
        ffmpeg -sseof -"$seconds" -i "$input" -c copy "$output"
      }

      fixaudio() {
        local outdir=""
        local files=()

        while [[ $# -gt 0 ]]; do
          case "$1" in
            -o)
              outdir="$2"
              shift 2
              ;;
            *)
              files+=("$1")
              shift
              ;;
          esac
        done

        if [[ ''${#files[@]} -eq 0 ]]; then
          echo "usage: fixaudio [-o outdir] <file|glob...>"
          return 1
        fi

        if [[ -n "$outdir" ]]; then
          mkdir -p "$outdir"
        fi

        for input in "''${files[@]}"; do
          if [[ ! -f "$input" ]]; then
            echo "skipping: $input (not a file)"
            continue
          fi

          local ext="''${input##*.}"
          local base="''${input%.*}"
          local filename="''${base##*/}_audiofix.''${ext}"

          if [[ -n "$outdir" ]]; then
            local output="$outdir/''${filename##*/}"
          else
            local output="''${base%/*}/''${filename##*/}"
          fi

          echo "fixing: $input -> $output"
          ffmpeg -i "$input" -c:v copy -c:a pcm_s16le "$output"
        done
      }

      resolvefix() {
        for f in "$@"; do
          ffmpeg -hide_banner -loglevel warning -stats -i "$f" -map 0:v:0 -map 0:a -c:v copy -c:a pcm_s16le "''${f:r}.tmp.mov" \
            && rm "$f" && mv "''${f:r}.tmp.mov" "''${f:r}.mov"
        done
      }
    '';
  };
}
