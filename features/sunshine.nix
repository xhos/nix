{
  flake.modules.nixos.sunshine = {
    config,
    lib,
    pkgs,
    ...
  }: {
    services.sunshine = {
      enable = true;
      # nvenc needs libcuda, which the default build can't find
      package = lib.mkIf config.nvidia.enable (pkgs.sunshine.override {cudaSupport = true;});
      autoStart = true;
      capSysAdmin = true; # needed for KMS capture on wayland
      openFirewall = true; # 47984-48010 tcp/udp, web ui on 47990
    };
  };

  flake.modules.homeManager.sunshine = {
    persist.dirs = [".config/sunshine"]; # pairing state, web ui credentials
  };
}
