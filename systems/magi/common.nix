# shared config for the magi cluster: three dell optiplex 5040s (melchior, balthasar, casper)
{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disko.nix {}) # module args ignore defaults, call it so disk ? applies
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  profile = "minimal";
  homelab.forgejo-runner.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  system.stateVersion = "26.11";
}
