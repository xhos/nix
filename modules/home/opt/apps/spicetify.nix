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
        beautifulLyrics
      ];
      enabledSnippets = with spicePkgs.snippets; [
        hideSidebarScrollbar
        smallVideoButton
        removeTopSpacing
        smoothProgressBar
      ];
    };
  };
}
