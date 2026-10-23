{
  config,
  lib,
  pkgs,
  ...
}: {
  options.homelab.forgejo-runner.enable = lib.mkEnableOption "forgejo actions runner";

  config = lib.mkIf config.homelab.forgejo-runner.enable {
    # TOKEN=<instance registration token from site admin -> actions -> runners>
    sops.secrets."env/forgejo-runner" = {};

    homelab.docker.enable = true;

    # registration and pulled images survive reboots
    persist.dirs = ["/var/lib/private/gitea-runner" "/var/lib/containers"];

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.default = {
        enable = true;
        name = config.networking.hostName;
        url = "https://git.${config.homelab.config.domain}";
        tokenFile = config.sops.secrets."env/forgejo-runner".path;
        labels = [
          "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-latest"
          # runs on the host against the system nix daemon
          "nix:host"
        ];
        hostPackages = with pkgs; [bash coreutils curl gawk gitMinimal gnused nix nodejs wget];
      };
    };
  };
}
