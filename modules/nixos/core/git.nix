{
  programs.git = {
    enable = true;
    config = {
      user = {
        name = "xhos";
        email = "60789741+xhos@users.noreply.github.com";
        signingKey = "/home/xhos/.ssh/github.pub";
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      url = {
        "https://github.com/" = {
          insteadOf = ["gh:"];
        };
        "git@github.com:xhos/" = {
          insteadOf = ["x:"];
        };
      };
      status = {
        branch = true;
        showStash = true;
        showUntrackedFiles = "all";
      };
      init.defaultBranch = "main";
    };
  };

  programs.lazygit.enable = true;
}
