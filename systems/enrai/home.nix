{pkgs, ...}: {
  impermanence.enable = true;
  headless = true;
  modules.secrets.enable = true;

  shell = "zsh";
  prompt = "starship";
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
}
