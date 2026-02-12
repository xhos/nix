{
  config,
  lib,
  ...
}: {
  home.sessionVariables = {
    WAKATIME_HOME = "${config.xdg.configHome}/wakatime";
    TERMINAL = lib.mkDefault "foot";
    PROTON_PASS_KEY_PROVIDER = "fs"; # pass-cli uses kernel keyring which seems to be bugged for now on my setup. TODO: remove once that's fixed.
  };
}
