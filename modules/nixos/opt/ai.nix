{
  config,
  lib,
  pkgs,
  ...
}: {
  options.ai.enable = lib.mkEnableOption "Ollama AI with CUDA acceleration";

  config = lib.mkIf config.ai.enable {
    services.ollama.enable = true;
    services.ollama.package = pkgs.ollama-cuda;
    # default is 4096, which a tool-heavy system prompt overflows silently
    services.ollama.environmentVariables.OLLAMA_CONTEXT_LENGTH = "16384";
  };
}
