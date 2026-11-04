{
  config,
  lib,
  ...
}: {
  # foot is always enabled for binds like clipse to work fast
  # https://codeberg.org/dnkl/foot/src/branch/master/foot.ini
  programs.foot = lib.mkIf (config.headless != true) {
    enable = true;
    server.enable = false;
    settings = {
      main = {
        shell = config.shell;
        app-id = "foot";
        title = "foot";
        locked-title = "no";
        term = "xterm-256color";
        resize-delay-ms = 100;
        selection-target = "primary";
        bold-text-in-bright = "yes";
        word-delimiters = ",│`|:\"'()[]{}<>";
        pad = "10x10";
      };

      cursor = {
        style = "beam";
        beam-thickness = 2;
      };

      scrollback = {
        lines = 10000;
        multiplier = 3;
      };
    };
  };
}
