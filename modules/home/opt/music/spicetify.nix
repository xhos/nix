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
