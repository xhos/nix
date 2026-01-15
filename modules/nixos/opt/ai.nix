{
  config,
  lib,
  ...
}: {
  options.ai.enable = lib.mkEnableOption "Ollama AI with CUDA acceleration";

  config = lib.mkIf config.ai.enable {
    services.ollama.enable = true;
    services.ollama.acceleration = "cuda";
  };
}
