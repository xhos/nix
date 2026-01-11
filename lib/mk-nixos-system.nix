{
  lib,
  inputs,
  import-tree,
  sharedNixosModules,
}: {
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
    ]
    ++ lib.optionals (homeUser != null) (
      sharedNixosModules
      ++ [
        {
          home-manager = {
            extraSpecialArgs = {inherit inputs import-tree;};
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
