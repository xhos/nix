{
  pkgs,
  lib,
  config,
  ...
}: {
  options.homelab.docker.enable = lib.mkEnableOption "container runtime with podman";

  config = lib.mkIf config.homelab.docker.enable {
    # podman works much better with custom netoworking and impermanence and nixos in general

    virtualisation = {
      containers = {
        enable = true;
        containersConf.settings.engine.compose_warning_logs = false;
      };

      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    environment.systemPackages = with pkgs; [
      fuse-overlayfs # rootless overlay driver
      slirp4netns # rootless networking
      fuse
    ];

    # keep containers running after logout
    users.users.xhos.linger = true;
  };
}
