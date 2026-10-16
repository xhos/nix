{
  modulesPath,
  pkgs,
  lib,
  ...
}: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  networking.hostName = "nyx";
  nixpkgs.hostPlatform = "x86_64-linux";

  # ZFS Support
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.forceImportRoot = false;
  boot.zfs.forceImportAll = false;
  networking.hostId = "12345678";

  # minimal ISO ships wpa_supplicant, not NetworkManager — `w` needs NM running
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = true;

  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    experimental-features = ["nix-command" "flakes"];
  };

  environment.systemPackages = with pkgs; [
    git
    zfs
    pcinfo
    (writeShellApplication {
      name = "i";
      text = ''
        exec nix run github:xhos/nix#installer
      '';
    })
    (writeShellApplication {
      name = "ir";
      text = ''
        exec nix run github:xhos/nix#installer --refresh
      '';
    })
    (writeShellApplication {
      name = "w";
      runtimeInputs = [networkmanager util-linux];
      text = ''
        dev=$(lsblk -o PATH,LABEL -pr | awk '$2 == "NIXKEYS" {print $1; exit}')
        [[ -b "$dev" ]] || { echo "NIXKEYS not found"; exit 1; }

        mnt=$(mktemp -d)
        mount -o ro "$dev" "$mnt"
        trap 'umount "$mnt"; rmdir "$mnt"' EXIT

        [[ -f "$mnt/keys/wifi" ]] || { echo "keys/wifi missing"; exit 1; }

        ssid=$(sed -n '1p' "$mnt/keys/wifi")
        pass=$(sed -n '2p' "$mnt/keys/wifi")

        nmcli dev wifi connect "$ssid" password "$pass"
      '';
    })
    # d = diagnostics, ds = diagnostics + 2 min stress test
    (writeShellScriptBin "d" ''exec pcinfo "$@"'')
    (writeShellScriptBin "ds" ''exec pcinfo -s 120'')
  ];

  # insecure, but i want to ssh to not fiddle with the laptop when installing
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root.password = lib.mkForce "nix";

  services.getty.autologinUser = lib.mkForce "root";

  system.stateVersion = "25.05";
}
