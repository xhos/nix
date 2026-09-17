{
  config,
  lib,
  ...
}: {
  options.syncthing = {
    enable = lib.mkEnableOption "sync obsidian notes via syncthing";

    ignorePatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        ignore patterns for the notes folder, shared by every device (leaf
        devices here, enrai in modules/nixos/opt/homelab/services/syncthing.nix).

        these MUST stay identical everywhere: enrai is the only hub, and
        syncthing never relays a peer's data, so anything one device ignores
        and another wants can never arrive -- it just sits at N% forever.

        conflict copies are made locally by whichever device loses the race, so
        ignoring them stops them propagating, not appearing. that's what we want
        for .obsidian churn (worthless, and ~75% of all conflicts), but NOT for
        real notes -- those need to reach enrai so notes-git-sync commits them.
      '';
      default = [
        "// managed by nixos, see modules/nixos/opt/syncthing.nix"
        "/.git"
        "/.trash"
        "(?d).obsidian/workspace*.json"
        "(?d).obsidian/*.sync-conflict-*"
        "(?d).obsidian/**/*.sync-conflict-*"
      ];
    };
  };

  config = lib.mkIf config.syncthing.enable {
    sops.secrets = {
      "syncthing/${config.networking.hostName}/cert".mode = "0400";
      "syncthing/${config.networking.hostName}/key".mode = "0400";
    };

    services.syncthing = {
      enable = true;
      user = "xhos";
      group = "users";
      dataDir = "/home/xhos/.local/share/syncthing";
      configDir = "/home/xhos/.config/syncthing";

      cert = config.sops.secrets."syncthing/${config.networking.hostName}/cert".path;
      key = config.sops.secrets."syncthing/${config.networking.hostName}/key".path;

      settings = {
        options.urAccepted = -1;
        devices."enrai".id = "VOGYGVF-P53JZY4-C2Q5ITL-VVFV34S-XKCUQTT-3D7BRXM-WGO2C3J-ODKARQT";

        folders."notes" = {
          path = "/home/xhos/Documents/notes";
          devices = ["enrai"];
          inherit (config.syncthing) ignorePatterns;
        };
      };

      openDefaultPorts = true;
    };
  };
}
