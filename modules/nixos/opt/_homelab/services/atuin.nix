{config, ...}: {
  _enrai.exposedServices.atuin = {
    port = config.services.atuin.port;
    exposed = true;
  };

  services.atuin.enable = true;
}
