{
  config,
  options,
  lib,
  pkgs,
  ...
}: {
  options.sunshine.enable = lib.mkEnableOption "sunshine game/desktop streaming host (pair with moonlight)";

  config = lib.mkIf config.sunshine.enable (lib.mkMerge [
    {
      services.sunshine = {
        enable = true;
        # nvenc needs libcuda, which the default build can't find
        package = lib.mkIf config.nvidia.enable (pkgs.sunshine.override {cudaSupport = true;});
        autoStart = true;
        capSysAdmin = true; # needed for KMS capture on wayland
        openFirewall = true; # 47984-48010 tcp/udp, web ui on 47990
      };
    }

    # pairing state + web ui credentials. guarded: hosts without home-manager
    # (homeUser = null) don't have the option, and mkIf false still needs it to exist
    (lib.optionalAttrs (options ? home-manager) {
      home-manager.users.xhos.persist.dirs = [".config/sunshine"];
    })
  ]);
}
