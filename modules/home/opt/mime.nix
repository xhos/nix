# inspo: https://github.com/Leifrstein/backup/blob/a0ae92c8eded62c5f65338457e0af92084002bc4/home-modules/mimeapps.nix
# and many others on github
# this mime shit is annoying ;-;
{
  pkgs,
  lib,
  config,
  ...
}: let
  terminal = "com.mitchellh.ghostty.desktop";
  browser = "zen-beta.desktop";
  editor = "dev.zed.Zed.desktop";
  fileManager = "org.gnome.Nautilus.desktop";
  imageViewer = "org.gnome.Loupe.desktop";
  pdfViewer = "org.gnome.Evince.desktop";
  videoPlayer = "io.github.celluloid_player.Celluloid.desktop";
  archiveManager = "org.gnome.FileRoller.desktop";

  # calibre, please, don't open .go files in a fucking ebook reader
  makeCalibreDesktop = name: exec: icon: ''
    [Desktop Entry]
    Type=Application
    Name=${name}
    Exec=${exec} %f
    Icon=${icon}
    MimeType=
    Categories=Office;
    NoDisplay=false
  '';
in {
  xdg = lib.mkIf (config.headless != true) {
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = fileManager;
        "text/*" = editor;
        "image/*" = imageViewer;
        "audio/*" = videoPlayer;
        "video/*" = videoPlayer;
        "text/html" = browser;
        "application/pdf" = pdfViewer;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;
        "x-scheme-handler/terminal" = terminal;
        "application/zip" = archiveManager;
        "application/x-7z-compressed" = archiveManager;
        "application/x-tar" = archiveManager;
        "application/gzip" = archiveManager;
        "application/x-rar" = archiveManager;
        "application/x-xz" = archiveManager;
      };

      associations.removed = let
        calibreApps = [
          "calibre-gui.desktop"
          "calibre-ebook-viewer.desktop"
          "calibre-ebook-edit.desktop"
        ];
        mimeTypes = [
          "text/plain"
          "text/html"
          "application/pdf"
          "inode/directory"
        ];
      in
        lib.listToAttrs (
          lib.flatten (
            map (
              mime:
                map (app: lib.nameValuePair mime app) calibreApps
            )
            mimeTypes
          )
        );
    };

    dataFile."applications/calibre-gui.desktop".text =
      makeCalibreDesktop "Calibre" "calibre" "calibre-gui";

    dataFile."applications/calibre-ebook-viewer.desktop".text =
      makeCalibreDesktop "Calibre E-book Viewer" "ebook-viewer" "calibre-viewer";

    dataFile."applications/calibre-ebook-edit.desktop".text =
      makeCalibreDesktop "Calibre E-book Editor" "ebook-edit" "calibre-ebook-edit";

    dataFile."applications/calibre-lrfviewer.desktop".text =
      makeCalibreDesktop "Calibre LRF Viewer" "lrfviewer" "calibre-viewer";
  };

  home.packages = with pkgs;
    lib.mkIf (config.headless != true) [
      handlr-regex

      (writeShellScriptBin "xdg-open" ''
        exec ${handlr-regex}/bin/handlr open "$@"
      '')
    ];

  # remove wine assosciations
  home.sessionVariables.WINEDLLOVERRIDES = "winemenubuilder.exe=d";
}
