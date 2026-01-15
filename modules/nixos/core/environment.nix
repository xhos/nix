{pkgs, ...}: {
  environment = {
    shells = [pkgs.zsh];
    variables.NH_FLAKE = "/home/xhos/nix";
    variables.EDITOR = "nvim";
    variables.NIXOS_OZONE_WL = "1";
    variables.WAKATIME_HOME = "/home/xhos/.config/wakatime";
    variables.CLAUDE_CONFIG_DIR = "/home/xhos/.config/claude";
  };
}
