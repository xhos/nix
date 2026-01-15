{
  config,
  lib,
  pkgs,
  ...
}: {
  security = {
    polkit.enable = true;

    sudo.extraConfig = ''
      Defaults:xhos lecture = never
      xhos ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/shutdown, /run/current-system/sw/bin/poweroff, /run/current-system/sw/bin/reboot
      xhos ALL=(ALL) NOPASSWD: /usr/bin/shutdown, /usr/bin/poweroff, /usr/bin/reboot
      xhos ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/poweroff, /sbin/reboot
    '';

    pam.services = lib.mkIf (config.headless != true) {
      greetd = {
        gnupg.enable = true;
        enableGnomeKeyring = true;
      };
      login = {
        enableGnomeKeyring = true;
        gnupg = {
          enable = true;
          noAutostart = true;
          storeOnly = true;
        };
      };
    };
  };

  systemd.user.services.polkit-gnome-authentication-agent-1 = lib.mkIf (config.headless != true) {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = ["graphical-session.target"];
    wants = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
