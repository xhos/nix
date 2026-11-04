{
  flake.modules.nixos.desktop = {
    lib,
    pkgs,
    ...
  }: {
    environment = {
      systemPackages = with pkgs; [
        nautilus
        nautilus-python
        ffmpegthumbnailer
        gnome-font-viewer
        gnome-epub-thumbnailer
        libgsf
      ];

      # extensions and thumbnailers are found through the system profile
      sessionVariables.NAUTILUS_4_EXTENSION_DIR = lib.mkForce "/run/current-system/sw/lib/nautilus/extensions-4";
      pathsToLink = [
        "/share/nautilus-python/extensions"
        "/share/thumbnailers"
      ];
    };

    services.gvfs.enable = true; # trash, phones, network shares
    services.gnome.sushi.enable = true; # spacebar preview
  };

  flake.modules.homeManager.desktop = {
    xdg.mimeApps.defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";

    persist.dirs = [
      ".local/share/nautilus"
      ".local/share/gvfs-metadata" # per-folder view and sort
      ".cache/thumbnails"
      ".config/gtk-3.0/" # sidebar bookmarks
    ];
  };
}
