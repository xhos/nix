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

  imageTypes = [
    "image/jpeg"
    "image/png"
    "image/gif"
    "image/webp"
    "image/tiff"
    "image/bmp"
    "image/svg+xml"
    "image/svg+xml-compressed"
    "image/avif"
    "image/heic"
    "image/jxl"
    "image/x-tga"
    "image/x-dds"
    "image/vnd-ms.dds"
    "image/vnd.microsoft.icon"
    "image/vnd.radiance"
    "image/x-exr"
    "image/x-portable-bitmap"
    "image/x-portable-graymap"
    "image/x-portable-pixmap"
    "image/x-portable-anymap"
    "image/qoi"
    "image/x-qoi"
  ];
  audioTypes = [
    "audio/mpeg"
    "audio/mp4"
    "audio/aac"
    "audio/flac"
    "audio/ogg"
    "audio/opus"
    "audio/vorbis"
    "audio/webm"
    "audio/wav"
    "audio/x-wav"
    "audio/x-matroska"
  ];
  videoTypes = [
    "video/mp4"
    "video/mpeg"
    "video/x-matroska"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/x-flv"
    "video/x-ms-wmv"
    "video/3gpp"
    "video/ogg"
  ];
  textTypes = [
    "text/plain"
    "text/markdown"
    "text/x-markdown"
    "application/json"
    "application/toml"
    "application/x-yaml"
    "text/x-python"
    "text/x-shellscript"
    "text/x-c"
    "text/x-c++"
    "text/x-go"
    "text/x-rust"
    "text/x-nix"
    "text/css"
    "application/javascript"
    "application/xml"
    "text/xml"
  ];

  assoc = types: app: lib.listToAttrs (map (t: lib.nameValuePair t app) types);

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
      defaultApplications =
        assoc imageTypes imageViewer
        // assoc audioTypes videoPlayer
        // assoc videoTypes videoPlayer
        // assoc textTypes editor
        // {
          "inode/directory" = fileManager;
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
