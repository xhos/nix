{
  config,
  lib,
  pkgs,
  ...
}: {
  options.nvidia.enable = lib.mkEnableOption "NVIDIA GPU support with CUDA";

  config = lib.mkIf config.nvidia.enable {
    hardware.nvidia = {
      modesetting.enable = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    services.xserver.videoDrivers = ["nvidia"];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_DRM_NO_MODIFIERS = "1";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    environment.systemPackages = with pkgs; [
      cudatoolkit
      cudaPackages.cudnn
    ];
  };
}
