{pkgs, ...}: {
  users = {
    users.xhos = {
      isNormalUser = true;
      hashedPassword = "$6$ZlO7m5FSFqgh5z88$VOfxfXPMq.Vv5K4LEWrzbyZ218Nxl5tdZrO20M.BxZ2swydwGqRY8HgnUpmW0CPJB6rV51hXfPP9LBO9C9H4i1";
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
        "libvirtd"
        "docker"
        "input"
      ];
    };
    defaultUserShell = pkgs.zsh;
  };
}
