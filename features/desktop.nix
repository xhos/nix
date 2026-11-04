{config, ...}: {
  flake.modules.nixos.desktop.home-manager.sharedModules = [
    config.flake.modules.homeManager.desktop
  ];
}
