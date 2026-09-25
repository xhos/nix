{pkgs, ...}: {
  # stylix.image = pkgs.fetchurl {
  #   url = "https://realmafricasafaris.com/wp-content/uploads/2020/02/The-Shoebill-Stork.jpg";
  #   sha256 = "sha256-/kIfVH281mZ8YfITslwQEwuje0aPDNsEkgQwsb6X0no=";
  # };
  #
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/og/wallhaven-ogj1gl.jpg";
    sha256 = "sha256-FXNqSqynxQPF6zNjGXymzLy+a7iaDZdR7M95wmWrisY=";
  };
  # stylix.base16Scheme = ./min-dark.yaml;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/material-darker.yaml";

  impermanence.enable = true;

  modules = {
    rofi.enable = true;
    spicetify.enable = true;
    discord.enable = true;
    secrets.enable = true;
    telegram.enable = true;
    fonts.enable = true;
    rclone.enable = true;
    kdeconnect.enable = true;
  };

  wm = "hyprland";
  bar = "waybar";
  shell = "zsh";
  prompt = "starship";
  browser = "zen";

  mainMonitor = "Microstep MAG 274UPF E2 0x00000001";

  modules.smokeapi = {
    enable = true;
    appId = 2161700;
    additionalLibraryPaths = ["/games/SteamLibrary"];
  };

  hyprland.execOnce = [
    "spotify"
    "materialgram"
    "discord"
  ];

  home.packages = with pkgs; [
    assetto-corsa-env
    jetbrains.idea
    teams-for-linux
    # whspr # broken: ctranslate2 build failure
    # android-studio-full
  ];

  xdg.desktopEntries.assetto-corsa-cm = {
    name = "Assetto Corsa Content Manager";
    exec = "${pkgs.assetto-corsa-env}/bin/assetto-corsa-env cm %u";
    icon = "steam_icon_244210";
    categories = ["Game"];
    mimeType = ["x-scheme-handler/acmanager"];
    terminal = false;
  };

  xdg.desktopEntries.assetto-corsa-installer = {
    name = "Run in Assetto Corsa";
    exec = "${pkgs.assetto-corsa-env}/bin/assetto-corsa-env run %f";
    icon = "steam_icon_244210";
    categories = ["Game"];
    mimeType = ["application/x-ms-dos-executable" "application/vnd.microsoft.portable-executable"];
    noDisplay = true;
    terminal = false;
  };

  xdg.mimeApps.defaultApplications."x-scheme-handler/acmanager" = ["assetto-corsa-cm.desktop"];

  wayland.windowManager.hyprland.extraLuaFiles."assetto-corsa" = {
    autoLoad = true;
    content = ''
      -- CM dropdowns share the shell's class/title. Tag only a verified
      -- explorer.exe /desktop process with the observed tiny window shape.
      local function hide_ac_shell(w)
        if w.class ~= "steam_app_244210" or w.title ~= "" or not w.floating then return end
        if w.size.x <= 0 or w.size.x > 200 or w.size.y <= 0 or w.size.y > 32 then return end
        local proc = "/proc/" .. tostring(w.pid)
        local f = io.open(proc .. "/comm", "r")
        if not f then return end
        local comm = f:read("*l")
        f:close()
        if comm ~= "explorer.exe" then return end
        f = io.open(proc .. "/cmdline", "r")
        if not f then return end
        local cmd = f:read("*a"):gsub("%z", " "):lower()
        f:close()
        if not cmd:match("/desktop%s*$") then return end
        hl.dispatch(hl.dsp.window.tag({ window = w, tag = "+ac-explorer-desktop" }))
      end

      hl.window_rule({
        name = "assetto-corsa-explorer-only",
        match = { tag = "ac-explorer-desktop" },
        opacity = "0.0 override 0.0 override 0.0 override",
        no_focus = true,
        no_anim = true,
        no_blur = true,
        no_shadow = true,
        decorate = false,
      })
      hl.on("window.open", hide_ac_shell)
      for _, w in ipairs(hl.get_windows()) do hide_ac_shell(w) end
    '';
  };
}
