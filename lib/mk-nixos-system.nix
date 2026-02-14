{
  lib,
  inputs,
  import-tree,
  sharedNixosModules,
}: let
  pkgsOverlay = (import ./pkgs-overlay.nix lib) ../pkgs;
in {
  hostname,
  homeUser ? "xhos",
  extraSpecialArgs ? {},
  minimal ? false,
}:
lib.nixosSystem {
  specialArgs = {inherit inputs import-tree;} // extraSpecialArgs;
  modules =
    lib.optionals (!minimal) [../modules/nixos]
    ++ [
      (import-tree.forHost hostname ../modules/nixos)
      {nixpkgs.overlays = [pkgsOverlay];}
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
              (import-tree.forHost hostname ../modules/home)
            ];
          };
        }
      ]
    )
    ++ lib.optionals (homeUser == null) [
      inputs.stylix.nixosModules.stylix
      inputs.impermanence.nixosModules.impermanence
    ];
}
