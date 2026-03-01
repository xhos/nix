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

      # impermanence
      imp = ''
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
      '';
      nimp = "sudo ncdu -x /";

      u = "uwsm-app --";
    };

    initContent = ''
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
    '';
  };
}
