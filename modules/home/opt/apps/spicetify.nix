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

      spotifyPackage = inputs.transparent-spotify.packages.${pkgs.stdenv.hostPlatform.system}.spotify-transparent;

      theme = spicePkgs.themes.dribbblish;

      customColorScheme = with config.lib.stylix.colors; {
        text = base05;
        subtext = base04;
        main = base00;
        main-elevated = base01;
        sidebar = base00;
        player = base00;
        card = base01;
        highlight = base02;
        highlight-elevated = base02;
        tab-active = base02;
        header = base03;
        misc = base03;
        selected-row = base05;
        button = base0D;
        button-active = base0C;
        button-disabled = base03;
        accent = base0D;
        accent-active = base0C;
        accent-inactive = base00;
        banner = base0D;
        border-active = base0D;
        border-inactive = base01;
        notification = base0C;
        notification-error = base08;
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
        smallVideoButton
        removeTopSpacing
        smoothProgressBar
        (builtins.readFile ./spicetify.css)
      ];
    };

    # spotify is evil so we have to set the cache max size like this
    home.activation.spotifyCacheCap = lib.hm.dag.entryAfter ["writeBoundary"] ''
      prefs="${config.xdg.configHome}/spotify/prefs"
      if [ -f "$prefs" ]; then
        run sed -i '/^storage.size=/d' "$prefs"
        run sh -c 'echo storage.size=2048 >> "$1"' _ "$prefs"
      fi
    '';
  };
}
