{
  lib,
  inputs,
  import-tree,
  sharedNixosModules,
}: let
  pkgsOverlay = (import ./pkgs-overlay.nix lib) ../pkgs;
in
  {
    hostname,
    homeUser ? "xhos",
    extraSpecialArgs ? {},
    minimal ? false,
    homelab ? false,
  }:
    lib.nixosSystem {
      specialArgs = {inherit inputs import-tree;} // extraSpecialArgs;
      modules =
        lib.optionals (!minimal) [../modules/nixos]
        ++ [
          ../systems/${hostname}/configuration.nix
          {nixpkgs.overlays = [pkgsOverlay];}
        ]
        ++ lib.optionals homelab [
          (import-tree ../modules/nixos/opt/_homelab)
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
                  ../modules/home
                  ../systems/${hostname}/home.nix
                ];
              };
            }
          ]
        )
        ++ lib.optionals (homeUser == null && !minimal) [
          inputs.stylix.nixosModules.stylix
          inputs.impermanence.nixosModules.impermanence
        ];
    }
