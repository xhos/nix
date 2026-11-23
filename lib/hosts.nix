# each systems/<host>/configuration.nix declares hosts.<host>; this turns them into nixosConfigurations
{
  inputs,
  lib,
  config,
  ...
}: let
  mkNixosSystem = import ./mk-nixos-system.nix {
    inherit lib inputs;
    import-tree = import ./import-tree.nix {inherit inputs;};
    # shared modules across all hosts with home-manager
    sharedNixosModules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.stylix.nixosModules.stylix
      inputs.impermanence.nixosModules.impermanence
      inputs.vpn-confinement.nixosModules.default
    ];
  };
in {
  options.hosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        features = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          default = [];
          description = "flake.modules.nixos.* this host is built from";
        };
        homeUser = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "xhos";
        };
        nixos = lib.mkOption {
          type = lib.types.deferredModule;
          default = {};
          description = "the host's own nixos config";
        };
        home = lib.mkOption {
          type = lib.types.deferredModule;
          default = {};
          description = "the host's own home-manager config, for homeUser";
        };
        minimal = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "skip modules/nixos entirely";
        };
      };
    });
    default = {};
  };

  config.flake.nixosConfigurations =
    lib.mapAttrs (hostname: host:
      mkNixosSystem {
        inherit hostname;
        inherit (host) features nixos home homeUser minimal;
      })
    config.hosts;
}
