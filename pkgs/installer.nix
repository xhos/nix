{pkgs}: let
  keysLabel = "NIXKEYS";
  repoUrl = "git@github.com:xhos/nix.git";
  workdir = "/tmp/nix";
  keysDir = "/run/installer-keys";
in
  pkgs.writeShellApplication {
    name = "installer";

    runtimeInputs = with pkgs; [
      git
      jq
      gum
      sops
      util-linux
      disko
    ];

    text = ''
      log() { printf "\033[1;34m::\033[0m %s\n" "$*"; }
      die() { printf "\033[1;31m::\033[0m %s\n" "$*" >&2; exit 1; }

      setup_keys() {
        [[ -f "${keysDir}/sops" && -f ~/.ssh/github ]] && return 0

        log "looking for keys partition"
        local dev mnt
        dev=$(lsblk -o PATH,LABEL -pr | awk '$2 == "${keysLabel}" {print $1; exit}')
        [[ -b "$dev" ]] || die "${keysLabel} not found"

        mnt=$(mktemp -d)
        mount -o ro "$dev" "$mnt"
        trap 'umount "$mnt" 2>/dev/null; rmdir "$mnt" 2>/dev/null' RETURN

        [[ -f "$mnt/keys/github" ]] || die "github key missing"
        [[ -f "$mnt/keys/sops" ]]   || die "sops key missing"

        mkdir -p "${keysDir}"
        install -m600 "$mnt/keys/sops" "${keysDir}/sops"

        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        install -m600 "$mnt/keys/github" ~/.ssh/github
        cat > ~/.ssh/config << 'EOF'
      Host github.com
        IdentityFile ~/.ssh/github
        IdentitiesOnly yes
        StrictHostKeyChecking accept-new
        UserKnownHostsFile /dev/null
      EOF
        chmod 600 ~/.ssh/config

        log "keys ready"
      }

      clone_repo() {
        if [[ -d "${workdir}/.git" ]]; then
          git -C "${workdir}" fetch --prune -q
          git -C "${workdir}" reset --hard origin/HEAD -q
        else
          git clone --depth=1 "${repoUrl}" "${workdir}"
        fi
      }

      pick_host() {
        nix flake show "${workdir}" --json 2>/dev/null \
          | jq -r '.nixosConfigurations | keys[]' \
          | gum choose --header "pick host"
      }

      pick_disk() {
        lsblk -dpno NAME,SIZE,MODEL \
          | gum choose --header "pick disk" \
          | awk '{print $1}'
      }

      setup_keys
      clone_repo

      host=$(pick_host)
      [[ -n "$host" ]] || die "no host selected"

      disk=$(pick_disk)
      [[ -b "$disk" ]] || die "invalid disk"

      log "$host → $disk"
      gum confirm "this will wipe $disk" || exit 1

      # figure out what the host needs
      host_dir="${workdir}/modules/nixos/core/_$host"
      has_luks=false
      has_persist=false

      grep -q '"luks"' "$host_dir/disko.nix" 2>/dev/null && has_luks=true
      grep -rq 'impermanence' "$host_dir/" 2>/dev/null && has_persist=true

      if $has_luks; then
        log "luks detected, decrypting passphrase"
        SOPS_AGE_KEY_FILE="${keysDir}/sops" \
          sops -d --extract '["luks_password"]' \
          "${workdir}/secrets/secrets.yaml" > /tmp/luks-password
        trap 'rm -f /tmp/luks-password' EXIT
      fi

      extra_files=()
      if $has_persist; then
        extra_files+=(--extra-files "${keysDir}/sops" /persist/var/lib/sops-nix/key.txt)
      else
        extra_files+=(--extra-files "${keysDir}/sops" /var/lib/sops-nix/key.txt)
      fi

      log "installing $host"
      disko-install \
        --flake "${workdir}#$host" \
        --disk main "$disk" \
        "''${extra_files[@]}" \
        --write-efi-boot-entries

      gum style --foreground 82 --bold "done — reboot whenever"
    '';
  }
