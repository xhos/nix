{pkgs}: let
  keysLabel = "NIXKEYS";
  repoUrl = "git@github.com:xhos/nix.git";
  workdir = "/tmp/nix";
  keysRuntime = "/run/installer-keys";
in
  pkgs.writeShellApplication {
    name = "installer";
    runtimeInputs = with pkgs; [
      git
      jq
      gum
      rsync
      util-linux
      disko
    ];
    text = ''
      set -euo pipefail

      log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
      fail() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*" >&2; exit 1; }

      setup_keys() {
        [[ -f "${keysRuntime}/sops" && -f ~/.ssh/github ]] && return 0

        log "looking for ${keysLabel} partition..."
        local dev
        dev=$(lsblk -o PATH,LABEL -pr 2>/dev/null | awk '$2 == "${keysLabel}" {print $1; exit}')
        [[ -b "$dev" ]] || fail "${keysLabel} partition not found"

        local mnt
        mnt=$(mktemp -d)
        mount -o ro "$dev" "$mnt"

        [[ -f "$mnt/keys/github" ]] || { umount "$mnt"; fail "github key not found"; }
        [[ -f "$mnt/keys/sops" ]] || { umount "$mnt"; fail "sops key not found"; }

        mkdir -p "${keysRuntime}"
        cp "$mnt/keys/sops" "${keysRuntime}/sops"
        chmod 600 "${keysRuntime}/sops"

        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        cp "$mnt/keys/github" ~/.ssh/github
        chmod 600 ~/.ssh/github

        cat > ~/.ssh/config << 'EOF'
      Host github.com
        IdentityFile ~/.ssh/github
        IdentitiesOnly yes
        StrictHostKeyChecking accept-new
        UserKnownHostsFile /dev/null
      EOF
        chmod 600 ~/.ssh/config

        umount "$mnt" && rmdir "$mnt"
        log "keys configured"
      }

      clone_repo() {
        if [[ -d "${workdir}/.git" ]]; then
          log "updating repo"
          git -C "${workdir}" fetch --prune --quiet
          git -C "${workdir}" reset --hard origin/HEAD --quiet
        else
          log "cloning repo"
          git clone --depth=1 "${repoUrl}" "${workdir}"
        fi
      }

      select_host() {
        local host
        host=$(nix flake show "${workdir}" --json 2>/dev/null \
          | jq -r '.nixosConfigurations | keys[]' \
          | gum choose --header "select host")
        [[ -n "$host" ]] || fail "no host selected"
        echo "$host"
      }

      select_disk() {
        local header="$1"
        local exclude="''${2:-}"
        local disk
        if [[ -n "$exclude" ]]; then
          disk=$(lsblk -dpno NAME,SIZE,MODEL | grep -v "$exclude" | gum choose --header "$header" | awk '{print $1}')
        else
          disk=$(lsblk -dpno NAME,SIZE,MODEL | gum choose --header "$header" | awk '{print $1}')
        fi
        [[ -b "$disk" ]] || fail "invalid disk: $disk"
        echo "$disk"
      }

      # ── main ──────────────────────────────────────────────────────────
      setup_keys
      clone_repo

      HOST=$(select_host)
      HOST_DIR="${workdir}/modules/nixos/core/_$HOST"
      [[ -d "$HOST_DIR" ]] || fail "host directory not found: $HOST_DIR"
      log "selected: $HOST"

      # ── check for disko config ────────────────────────────────────────
      DISKO_CONFIG="$HOST_DIR/disko.nix"
      USE_DISKO=false
      if [[ -f "$DISKO_CONFIG" ]]; then
        USE_DISKO=true
        log "found disko.nix - will partition automatically"
      fi

      # ── check for impermanence ────────────────────────────────────────
      USE_PERSIST=false
      if nix eval "${workdir}#nixosConfigurations.$HOST.config.impermanence.enable" 2>/dev/null | grep -q "true"; then
        USE_PERSIST=true
        log "impermanence enabled for this host"
      fi

      # ── disk selection & partitioning ─────────────────────────────────
      if $USE_DISKO; then
        SYSTEM_DISK=$(select_disk "select SYSTEM disk (SSD) for $HOST")
        DATA_DISK=$(select_disk "select DATA disk (HDD) for $HOST" "$SYSTEM_DISK")

        gum confirm "WARNING: this will WIPE $SYSTEM_DISK and $DATA_DISK" || exit 1

        log "running disko on $SYSTEM_DISK (system) and $DATA_DISK (data)"
        disko --mode destroy,format,mount \
          --argstr disk "$SYSTEM_DISK" \
          --argstr dataDisk "$DATA_DISK" \
          "$DISKO_CONFIG"
      else
        log "no disko.nix - assuming manual partitioning"
        mountpoint -q /mnt || fail "/mnt not mounted - partition and mount manually first"
        mountpoint -q /mnt/boot || fail "/mnt/boot not mounted"
      fi

      # ── verify mounts ─────────────────────────────────────────────────
      mountpoint -q /mnt || fail "/mnt not mounted after disko"
      mountpoint -q /mnt/boot || fail "/mnt/boot not mounted"
      if $USE_PERSIST; then
        mountpoint -q /mnt/persist || fail "/mnt/persist not mounted (required for impermanence)"
      fi

      # ── generate hardware config ──────────────────────────────────────
      log "generating hardware-configuration.nix"
      nixos-generate-config --root /mnt --no-filesystems
      cp /mnt/etc/nixos/hardware-configuration.nix "$HOST_DIR/hardware-configuration.nix"

      # ── determine paths based on impermanence ─────────────────────────
      if $USE_PERSIST; then
        FLAKE_PATH="/mnt/persist/etc/nixos"
        SOPS_DEST="/mnt/persist/var/lib/sops-nix"
      else
        FLAKE_PATH="/mnt/etc/nixos"
        SOPS_DEST="/mnt/var/lib/sops-nix"
      fi

      # ── sync config ───────────────────────────────────────────────────
      log "syncing config to $FLAKE_PATH"
      mkdir -p "$FLAKE_PATH"
      rsync -a --delete "${workdir}/" "$FLAKE_PATH/"

      # ── install sops key ──────────────────────────────────────────────
      log "installing sops key to $SOPS_DEST"
      mkdir -p "$SOPS_DEST"
      cp "${keysRuntime}/sops" "$SOPS_DEST/key.txt"
      chmod 600 "$SOPS_DEST/key.txt"

      # ── install NixOS ─────────────────────────────────────────────────
      log "installing NixOS for $HOST"
      nixos-install --root /mnt --flake "path:$FLAKE_PATH#$HOST" --no-root-passwd

      gum style --foreground 82 --bold "done - reboot when ready"
    '';
  }