{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.networking) hostName;

  uuids = {
    melchior = "486946ea-52cf-482a-8cbf-faff6fa34fc5";
    balthasar = "ee396ac0-5ff7-437d-9029-8a4ac0ac8aa7";
    casper = "f3c3eaee-f45a-46a7-945e-064548508c27";
  };
in {
  options.homelab.forgejo-runner.enable = lib.mkEnableOption "forgejo actions runner";

  config = lib.mkIf config.homelab.forgejo-runner.enable {
    sops.secrets."forgejo-runner/${hostName}/token" = {};

    homelab.docker.enable = true;

    # pulled images survive reboots
    persist.dirs = ["/var/lib/private/forgejo-runner" "/var/lib/containers"];

    services.forgejo-runner = {
      package = pkgs.forgejo-runner;
      instances.default = {
        enable = true;
        settings = {
          server.connections.default = {
            url = "https://git.${config.homelab.config.domain}";
            uuid = uuids.${hostName};
          };
          runner.labels = [
            "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-latest"
            "nix:host"
          ];
        };
        secrets.server.connections.default.token_url = config.sops.secrets."forgejo-runner/${hostName}/token".path;
        hostPackages = with pkgs; [bash coreutils curl gawk gitMinimal gnused nix nodejs wget];
      };
    };
  };
}
