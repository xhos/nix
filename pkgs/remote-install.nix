# install a host over ssh with nixos-anywhere, from a machine that has this repo
# and the sops age key. the target just needs to be booted into nyx (iso or netboot).
# the host's ssh key comes from sops (host-keys/<host>), so it's a sops recipient
# from first boot and keeps the same identity across reinstalls
{pkgs}:
pkgs.writeShellApplication {
  name = "remote-install";

  runtimeInputs = with pkgs; [
    nixos-anywhere
    sops
    openssh
  ];

  text = ''
    log() { printf "\033[1;34m::\033[0m %s\n" "$*"; }
    die() { printf "\033[1;31m::\033[0m %s\n" "$*" >&2; exit 1; }

    [[ $# -eq 2 ]] || die "usage: remote-install <host> <ip>"
    host=$1
    target=$2
    [[ -f flake.nix && -d "systems/$host" ]] || die "run from the flake root (no systems/$host here)"

    # the locked nix-secrets input, i.e. what the host will decrypt with
    secrets="$(nix eval --raw --impure --expr "(builtins.getFlake (toString ./.)).inputs.nix-secrets.outPath")/secrets.yaml"

    extra=$(mktemp -d)
    trap 'rm -rf "$extra"' EXIT

    # impermanence hosts bind /etc/ssh from /persist
    ssh_dir="$extra/etc/ssh"
    if [[ $(nix eval --json ".#nixosConfigurations.$host.config.impermanence.enable") == true ]]; then
      ssh_dir="$extra/persist/etc/ssh"
    fi
    install -d -m755 "$ssh_dir"

    log "decrypting host key for $host"
    (umask 077; sops -d --extract "[\"host-keys\"][\"$host\"]" "$secrets" > "$ssh_dir/ssh_host_ed25519_key") \
      || die "no host-keys/$host in secrets"
    ssh-keygen -y -f "$ssh_dir/ssh_host_ed25519_key" > "$ssh_dir/ssh_host_ed25519_key.pub"

    # nyx's root password, nixos-anywhere uses it to copy our key over
    export SSHPASS=''${SSHPASS:-nix}

    log "installing $host on $target"
    nixos-anywhere \
      --env-password \
      --flake ".#$host" \
      --extra-files "$extra" \
      --generate-hardware-config nixos-generate-config "systems/$host/hardware-configuration.nix" \
      "root@$target"

    log "done, commit systems/$host/hardware-configuration.nix"
  '';
}
