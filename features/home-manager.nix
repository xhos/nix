# importing a feature on a host brings its home half along
{
  config,
  lib,
  ...
}: {
  flake.modules.nixos =
    lib.mapAttrs (_: module: {
      home-manager.sharedModules = [module];
    })
    config.flake.modules.homeManager;
}
