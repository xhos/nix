{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [inputs.spicetify-nix.homeManagerModules.default];

  options.modules.spicetify.enable = lib.mkEnableOption "Spicetify for Spotify theming";

  config = lib.mkIf config.modules.spicetify.enable {
    programs.spicetify = let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in {
      enable = true;
      theme = spicePkgs.themes.dribbblish;
      customColorScheme = with config.lib.stylix.colors; {
        accent = "${green}";
        accent-active = "${green}";
        accent-inactive = "${base00}";
        banner = "${green}";
        border-active = "${green}";
        border-inactive = "${base01}";
        header = "${base03}";
        highlight = "${base03}";
        main = "${base00}";
        notification = "${cyan}";
        notification-error = "${red}";
        subtext = "${base04}";
        text = "${base07}";
      };
      enabledExtensions = with spicePkgs.extensions; [
        shuffle
        hidePodcasts
        allOfArtist
        catJamSynced
        coverAmbience
        spicyLyrics
      ];
      enabledSnippets = with spicePkgs.snippets; [
        hideSidebarScrollbar
        smallVideoButton
        removeTopSpacing
        smoothProgressBar
      ];
    };

    # spotify rewrites prefs itself, so patch the line instead of symlinking the file
    home.activation.spotifyCacheCap = lib.hm.dag.entryAfter ["writeBoundary"] ''
      prefs="${config.xdg.configHome}/spotify/prefs"
      if [ -f "$prefs" ]; then
        run sed -i '/^storage.size=/d' "$prefs"
        run sh -c 'echo storage.size=2048 >> "$1"' _ "$prefs"
      fi
    '';
  };
}
