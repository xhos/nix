{
  config,
  lib,
  ...
}: {
  options.audio.enable = lib.mkEnableOption "PipeWire audio system";

  config = lib.mkIf config.audio.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
