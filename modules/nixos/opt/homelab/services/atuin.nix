{
  config,
  lib,
  ...
}: {
  options.homelab.atuin.enable = lib.mkEnableOption "atuin shell history sync server";

  config = lib.mkIf config.homelab.atuin.enable {
    _enrai.exposedServices.atuin = {
      port = config.services.atuin.port;
      exposed = true;
    };

    services.atuin.enable = true;
  };
}
