{
  inputs,
  config,
  lib,
  ...
}: let
  sopsFolder = toString inputs.nix-secrets;
  homeDirectory = config.home.homeDirectory;
in {
  imports = [inputs.sops-nix.homeManagerModules.sops];

  options.modules.secrets.enable = lib.mkEnableOption "SOPS secrets management";

  config = lib.mkIf config.modules.secrets.enable {
    sops = {
      age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

      defaultSopsFile = "${sopsFolder}/secrets.yaml";
      validateSopsFiles = false;

      secrets = {
        "wakatime" = {
          path = "${homeDirectory}/.config/wakatime/.wakatime.cfg";
          mode = "0444";
        };
      };
    };
  };
}
