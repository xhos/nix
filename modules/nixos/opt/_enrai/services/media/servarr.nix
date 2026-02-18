{
  lib,
  config,
  inputs,
  ...
}: {
  imports = [inputs.declarr.nixosModules.default];

  # shared media directory
  systemd.tmpfiles.rules = [
    "d /storage/media 0775 root media -"
  ];

  # declarr global config
  services.declarr = {
    enable = true;
    config.declarr = {
      stateDir = "/var/lib/declarr";
      formatDbRepo = "https://github.com/Dictionarry-Hub/Database";
      formatDbBranch = "stable";
      globalResolvePaths = [
        "$.*.config.host.apiKey"
        "$.*.config.host.password"
        "$.*.config.host.passwordConfirmation"
        "$.*.downloadClient.*.fields.password"
        "$.*.applications.*.fields.apiKey"
        "$.*.indexer.*.fields.password"
      ];
    };
  };

  # shared secrets
  sops.secrets."media/password/qbit" = {
    group = "media";
    mode = "0440";
  };

  # media users and groups
  users = let
    mediaServices = ["sonarr" "radarr" "prowlarr"];
  in {
    users =
      lib.genAttrs mediaServices (name: {
        isSystemUser = true;
        group = name;
        extraGroups = ["media"];
      })
      // {declarr.extraGroups = ["media"];};
    groups = lib.genAttrs (mediaServices ++ ["media"]) (_: {});
  };

  # services without their own file
  services.flaresolverr.enable = true;
  _enrai.exposedServices.flaresolverr.port = config.services.flaresolverr.port;
}
