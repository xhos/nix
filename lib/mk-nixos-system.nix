{
  lib,
  inputs,
  import-tree,
  sharedNixosModules,
}: let
  pkgsOverlay = (import ./pkgs-overlay.nix lib) ../pkgs;

  erosanixOverlay = _final: prev: {
    mkWindowsApp = prev.callPackage "${inputs.erosanix}/pkgs/mkwindowsapp" {
      makeBinPath = prev.lib.makeBinPath;
    };

    mkWindowsAppNoCC = prev.callPackage "${inputs.erosanix}/pkgs/mkwindowsapp" {
      stdenv = prev.stdenvNoCC;
      makeBinPath = prev.lib.makeBinPath;
    };

    makeDesktopIcon = prev.callPackage "${inputs.erosanix}/lib/makeDesktopIcon.nix" {};

    copyDesktopIcons =
      prev.makeSetupHook {name = "copyDesktopIcons";}
      "${inputs.erosanix}/hooks/copy-desktop-icons.sh";
  };

  collectFlakeInputs = input:
    [input] ++ builtins.concatMap collectFlakeInputs (builtins.attrValues (input.inputs or {}));
in
  {
    hostname,
    homeUser ? "xhos",
    extraSpecialArgs ? {},
    minimal ? false,
    rootInputs ? homeUser != null,
  }:
    lib.nixosSystem {
      specialArgs = {inherit inputs import-tree;} // extraSpecialArgs;
      modules =
        lib.optionals (!minimal) [../modules/nixos/default.nix]
        ++ [
          ../systems/${hostname}/configuration.nix
          {nixpkgs.overlays = [erosanixOverlay pkgsOverlay];}
        ]
        ++ lib.optionals rootInputs [
          {system.extraDependencies = collectFlakeInputs inputs.self;}
        ]
        ++ lib.optionals (homeUser != null) (
          sharedNixosModules
          ++ [
            {
              home-manager = {
                useGlobalPkgs = true;
                extraSpecialArgs = {inherit inputs import-tree hostname;};
                backupFileExtension = ".b";
                users.${homeUser}.imports = [
                  ../modules/home/default.nix
                  ../systems/${hostname}/home.nix
                ];
              };
            }
          ]
        )
        ++ lib.optionals (homeUser == null && !minimal) [
          inputs.stylix.nixosModules.stylix
          inputs.impermanence.nixosModules.impermanence
          inputs.vpn-confinement.nixosModules.default
        ];
    }
