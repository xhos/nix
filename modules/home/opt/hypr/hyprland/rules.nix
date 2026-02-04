{
  lib,
  config,
  ...
}: {
  wayland.windowManager.hyprland.settings = lib.mkIf (config.de == "hyprland") {
    layerrule = [
      "blur on, match:namespace ^(RegularWindow)$"
      "blur on, match:namespace ^(PopupWindow)$"

      "blur on, match:namespace ^(notifications)$"
      "ignore_alpha 0.0, match:namespace ^(notifications)$"

      "blur on, match:namespace ^(waybar)$"
      "ignore_alpha 0.0, match:namespace ^(waybar)$"
      "blur_popups on, match:namespace ^(waybar)$"

      "blur on, match:namespace ^(rofi)$"
      "ignore_alpha 0.0, match:namespace ^(rofi)$"

      "blur on, match:namespace ^(wvkbd)$"
      "blur on, match:namespace ^(gtk-layer-shell)$"
    ];

    windowrule = [
      # not sure if i need this anymore
      "match:class ^(xwaylandvideobridge)$, opacity 0.0 override, no_anim on, no_initial_focus on, max_size 1 1, no_blur on"

      # dim around
      "match:class ^(gcr-prompter)$, dim_around on"
      "match:class ^(xdg-desktop-portal-gtk)$, dim_around on"
      "match:class ^(polkit-gnome-authentication-agent-1)$, dim_around on"

      # floating rules
      "match:class ^(pavucontrol)$, float on, size 622 652"
      "match:class ^(blueman-manager)$, float on, size 622 652"
      "match:class ^(clipse)$, float on, size 622 652"
      "match:class ^(bluetui)$, float on, size 622 652"
      "match:class ^(impala)$, float on, size 622 652"
      "match:class ^(wiremix)$, float on, size 622 652"

      "match:class ^(nm-connection-editor)$, float on"
      "match:class ^(xdg-desktop-portal-gtk)$, float on"

      "match:title ^(Media viewer)$, float on"
      "match:title ^(Picture-in-Picture)$, float on, pin on"

      # make web apps tile properly
      "match:class web-app, tile on"

      # idle inhibit
      "match:class ^(mpv|.+exe|celluloid)$, idle_inhibit focus"
      "match:class ^(firefox)$, match:title ^(.*YouTube.*)$, idle_inhibit focus"
      "match:class ^(firefox)$, idle_inhibit fullscreen"

      # obsidian transparency
      "match:class ^(obsidian)$, opacity 0.99"
    ];
  };
}
