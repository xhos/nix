{
  lib,
  config,
  ...
}: {
  programs = lib.mkIf (config.wm == "niri") {
    niri.enable = true;
    uwsm = {
      enable = true;
      waylandCompositors.niri = {
        prettyName = "Niri";
        comment = "Niri scrollable-tiling compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/niri";
      };
    };
  };
}
