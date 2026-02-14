{inputs, ...}: {
  nix = {
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://cache.saumon.network/proxmox-nixos"
        "https://niri.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "proxmox-nixos:D9RYSWpQQC/msZUWphOY2I5RLH5Dd6yQcaHIuug7dWM="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];

      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      auto-optimise-store = true;
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 1d";
    };

    optimise.automatic = true;
  };

  # nix, esspecially with impermanence tends to open
  # a lot of files resulting in "too many open files"
  # errors. this fixes it. also, i have no idea which
  # one actually works :D
  boot.kernel.sysctl."fs.file-max" = 524288;
  systemd.user.extraConfig = "DefaultLimitNOFILE=524288";
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "524288";
    }
  ];

  system.stateVersion = "25.05";
}
