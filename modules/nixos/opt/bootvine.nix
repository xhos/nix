{
  config,
  lib,
  inputs,
  ...
}: {
  # live systemd job tree on the boot console, replaces plymouth (see bootloaders/)
  options.bootvine.enable = lib.mkEnableOption "bootvine boot console";

  imports = [inputs.bootvine.nixosModules.default];

  config = lib.mkIf config.bootvine.enable {
    services.bootvine.enable = true;

    nix.settings = {
      substituters = ["https://wvhulle.cachix.org"];
      trusted-public-keys = ["wvhulle.cachix.org-1:heXx8DZMiRsKUx6l1TxNoF+Nmtmz66QEdsonQzc1ir0="];
    };
  };
}
