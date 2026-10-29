{
  config,
  lib,
  ...
}: {
  # apps themselves are declared per-user in modules/home/opt/apps/flatpak.nix (nix-flatpak)
  config = lib.mkIf (!config.headless) {
    services.flatpak.enable = true;
  };
}
