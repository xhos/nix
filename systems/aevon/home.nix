{
  config,
  pkgs,
  ...
}: {
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";

  headless = true;

  modules.secrets.enable = true;

  modules.wsl = {
    windowsHome = "/mnt/c/Users/KudriaMa";
    memory = "10GB"; # host has 16GB
    terminalProfileGuid = "{41ae03f2-5542-51cf-a1c0-3a444db570ec}";
  };

  # eiad's own `build` devshell script compiles into .build/
  home.sessionPath = ["${config.home.homeDirectory}/work/eiad/.build"];

  shell = "zsh";
  prompt = "starship";
}
