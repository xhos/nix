{config, ...}: {
  xdg = {
    enable = true;
    cacheHome = config.home.homeDirectory + "/.cache";
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
