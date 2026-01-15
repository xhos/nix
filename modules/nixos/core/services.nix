{
  config.services = {
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        middleEmulation = true;
        naturalScrolling = true;
      };
    };

    dbus.enable = true;
    upower.enable = true;

    logind = {
      settings = {
        Login = {
          HandlePowerKey = "poweroff";
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "lock";
        };
      };
    };

    xserver.xkb = {
      layout = "us";
      options = "compose:rctrl,caps:escape";
    };

    gnome = {
      gnome-keyring.enable = true;
      glib-networking.enable = true;
    };
  };
}
