{
  config,
  lib,
  inputs,
  ...
}: {
  options.homelab.attic.enable = lib.mkEnableOption "binary cache";

  imports = [inputs.attic.nixosModules.atticd];

  config = let
    port = 8809;
  in
    lib.mkIf config.homelab.attic.enable {
      sops.secrets."env/attic" = {};

      persist.dirs = ["/var/lib/atticd"];

      homelab.exposedServices.attic.port = port;

      services.atticd = {
        enable = true;
        environmentFile = config.sops.secrets."env/attic".path;
        settings = {
          listen = "[::]:${toString port}";

          jwt = {};

          storage = {
            type = "s3";
            region = "auto";
            bucket = "nix-cache";
            endpoint = "https://3edcd62ccbf793af2e8ede645e115055.r2.cloudflarestorage.com";
          };

          chunking = {
            nar-size-threshold = 64 * 1024;
            min-size = 16 * 1024;
            avg-size = 64 * 1024;
            max-size = 256 * 1024;
          };
        };
      };
    };
}
