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

  # the real vault is on the windows side, see syncthing in configuration.nix
  home.file."Documents/notes".source = config.lib.file.mkOutOfStoreSymlink "/mnt/c/Users/KudriaMa/notes";

  shell = "zsh";
  prompt = "starship";
}
