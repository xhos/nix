{
  programs = {
    zsh.enable = true;
    dconf.enable = true;
    nix-ld.enable = true; # run generic linux binaries (zed remote agents etc)
    # ssh.startAgent = true;
  };

  environment.pathsToLink = ["/share/zsh"];
}
