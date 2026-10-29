{
  inputs,
  config,
  lib,
  ...
}: {
  imports = [inputs.nix-flatpak.homeManagerModules.nix-flatpak];

  # services.flatpak.enable defaults to the system's, see modules/nixos/opt/apps/flatpak.nix
  config = lib.mkIf (config.profile == "desktop") {
    services.flatpak.packages = [
      "io.github.CyberTimon.RapidRAW"
    ];
  };
}
