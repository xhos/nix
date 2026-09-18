{
  config,
  lib,
  ...
}: {
  options.homelab.atuin.enable = lib.mkEnableOption "atuin shell history sync server";

  config = lib.mkIf config.homelab.atuin.enable {
    homelab.exposedServices.atuin = {
      port = config.services.atuin.port;
      exposed = true;
      dashboard.group = null;
    };

    services.atuin.enable = true;
  };
}
