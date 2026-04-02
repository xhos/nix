{inputs, ...}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  headless = true;

  vm.enable = true;

  wsl.enable = true;
  wsl.defaultUser = "xhos";

  networking.hostName = "aevon";
  nixpkgs.hostPlatform = "x86_64-linux";

  programs.nix-ld.enable = true;
}
