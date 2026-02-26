{
  config,
  lib,
  ...
}: let
  # Binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  # workspaces = builtins.concatLists (builtins.genList (x: let
  #     ws = let c = (x + 1) / 10; in builtins.toString (x + 1 - (c * 10));
  #   in [
  #     "SUPER, ${ws}, workspace, ${toString (x + 1)}"
  #     "SUPERSHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
  #   ])
  #   10);
  workspaces = builtins.concatLists (
    builtins.genList (
      x: let
        ws = let
          c = (x + 1) / 10;
        in
          toString (x + 1 - (c * 10));
      in [
        "SUPER, ${ws}, split:workspace, ${toString (x + 1)}"
        "SUPERSHIFT, ${ws}, split:movetoworkspace, ${toString (x + 1)}"
      ]
    )
    10
  );
in {
  wayland.windowManager.hyprland.settings = lib.mkIf (config.wm == "hyprland") {
    # https://wiki.hyprland.org/Configuring/Binds/#bind-flags
    bind =
      [
        # Compositor commands
        "SUPER, C, killactive"
        "SUPER, S, togglesplit"
        "SUPER, E, exec, uwsm-app -- nautilus"
        "SUPER, F, fullscreen"
        "SUPER, P, pseudo"
        "SUPERSHIFT, P, pin"
        "SUPER, D, togglefloating"

        # Grouped (tabbed) windows
        "SUPER, G, togglegroup"
        "SUPER, TAB, changegroupactive, f"
        "SUPERSHIFT, TAB, changegroupactive, b"

        # Cycle through windows
        "ALT, Tab, cyclenext"
        "ALT, Tab, bringactivetotop"
        "ALTSHIFT, Tab, cyclenext, prev"
        "ALTSHIFT, Tab, bringactivetotop"

        # Move windows
        "SUPER, left, movewindow, l"
        "SUPER, right, movewindow, r"
        "SUPER, up, movewindow, u"
        "SUPER, down, movewindow, d"
        "SUPER, h, movewindow, l"
        "SUPER, l, movewindow, r"
        "SUPER, k, movewindow, u"
        "SUPER, j, movewindow, d"

        # Resize windows
        "SUPERSHIFT, right, resizeactive, 200 0"
        "SUPERSHIFT, left, resizeactive, -200 0"
        "SUPERSHIFT, up, resizeactive, 0 -200"
        "SUPERSHIFT, down, resizeactive, 0 200"
        "SUPERSHIFT, l, resizeactive, 200 0"
        "SUPERSHIFT, h, resizeactive, -200 0"
        "SUPERSHIFT, k, resizeactive, 0 -200"
        "SUPERSHIFT, j, resizeactive, 0 200"

        # Special workspaces
        "SUPERSHIFT, grave, movetoworkspace, special"
        "SUPER, grave, togglespecialworkspace"

        # cycle through workspaces
        "SUPERALT, up, split:workspace, m-1"
        "SUPERALT, down, split:workspace, m+1"
        "SUPERALT, k, split:workspace, m-1"
        "SUPERALT, j, split:workspace, m+1"
        "SUPER, mouse_down, split:workspace, e-1"
        "SUPER, mouse_up, split:workspace, e+1"

        # swap all windows between monitors
        "SUPERSHIFT, G, split:swapactiveworkspaces, current +1"
        "SUPERSHIFT, R, split:grabroguewindows"

        # utilities
        # "SUPER, Q, exec, uwsm-app -- ${terminal}"
        "SUPER, R, exec, uwsm-app -- whspr"
        "SUPER, B, exec, uwsm-app -- ${config.browser}"
        "SUPERSHIFT, L, exec, uwsm-app -- hyprlock"
        "SUPERSHIFT, S, exec, uwsm-app -- hyprshot -z -m region --clipboard-only"
        "SUPER, V, exec, uwsm-app -- foot -a clipse clipse"
        "SUPERSHIFT, B, exec, uwsm-app -- foot -a bluetui bluetui"
        "SUPERSHIFT, N, exec, uwsm-app -- foot -a impala impala"
        "SUPERSHIFT, A, exec, uwsm-app -- foot -a wiremix wiremix"
        "SUPERSHIFT, e, exec, uwsm-app -- bemoji"
        ",insert, exec, uwsm-app -- volume-script --toggle-mic"
        "ALT, code:65, exec, uwsm-app -- rofi -show drun -run-command 'uwsm-app -- {cmd}'"
      ]
      ++ workspaces;

    # will repeat while held
    binde = [
      ",XF86AudioRaiseVolume, exec, uwsm-app -- volume-script --inc"
      ",XF86AudioLowerVolume, exec, uwsm-app -- volume-script --dec"
      ",XF86AudioMute, exec, uwsm-app -- volume-script --toggle"

      ",XF86MonBrightnessUp, exec, uwsm-app -- brightness-script --inc"
      ",XF86MonBrightnessDown, exec, uwsm-app -- brightness-script --dec"
    ];

    # mouse bindings
    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];
  };
}
