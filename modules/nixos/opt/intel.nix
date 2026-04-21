{
  config,
  lib,
  pkgs,
  ...
}: {
  options.intel.enable = lib.mkEnableOption "intel xe support";

  config = lib.mkIf config.intel.enable {
    services.xserver.videoDrivers = ["modesetting"]; # just in case

    boot.initrd.kernelModules = ["i915"];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # VA-API for 11th Gen+ (iHD driver)
        intel-compute-runtime # OpenCL for 12th Gen+ (needed for Resolve)
        libvdpau-va-gl # VDPAU over VA-API
        libva-vdpau-driver # reverse bridge, useful for some apps
      ];
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD"; # VA-API driver: iHD = intel-media-driver (11th gen+), not legacy i965
      VDPAU_DRIVER = "va_gl"; # VDPAU over VA-API bridge, for apps that use VDPAU instead of VA-API
      SDL_RENDER_DRIVER = "opengl"; # Force SDL2 apps to use OpenGL renderer instead of falling back to software
      MESA_GL_VERSION_OVERRIDE = "4.5"; # Fixes Resolve crash: OpenCL-GL interop requires Mesa to report GL 4.5
    };
  };
}
