# following is taken from https://github.com/alper-han/ZyNixOS/blob/d8de8e20822486022e870987ca088b98e79a392d/modules/programs/media/davinci-resolve-studio/default.nix#L2
# Tested on Davinci 20.2.3 It works for loading videos and exporting in H264/5 & AV1
# Even if following this guide https://www.reddit.com/r/LinuxCrackSupport/comments/1nfqhld/davinci_resolve_studio_202_fix_linux_crack_guide/
# nixpkgs rev used for this tests: 4652ba995a945108fb891191c1e910b9a6ed9064
{
  lib,
  pkgs,
  config,
  ...
}: let
  ffmpeg-encoder-plugin = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "ffmpeg-encoder-plugin";
    version = "1.2.1";

    src = pkgs.fetchFromGitHub {
      owner = "EdvinNilsson";
      repo = "ffmpeg_encoder_plugin";
      tag = "v${finalAttrs.version}";
      hash = "sha256-F4Q8YCXD5UldTwLbWK4nHacNPQ/B+4yLL96sq7xZurM=";
    };

    nativeBuildInputs = with pkgs; [
      cmake
      ffmpeg
    ];

    buildInputs = with pkgs; [ffmpeg];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp ffmpeg_encoder_plugin.dvcp $out/

      runHook postInstall
    '';
  });

  davinci-resolve-studio-cracked = let
    davinci-patched = pkgs.davinci-resolve-studio.davinci.overrideAttrs (old: {
      # script based on https://www.reddit.com/r/LinuxCrackSupport/comments/1nfqhld/davinci_resolve_studio_202_fix_linux_crack_guide/
      #
      # Additionally, it will install ffmpeg_encoder_plugin to enable H264/5 & AV1 exports:
      # https://github.com/EdvinNilsson/ffmpeg_encoder_plugin
      #
      # Note: $out IS /opt/resolve
      postInstall = ''
        ${old.postInstall or ""}
        ${lib.getExe pkgs.perl} -pi -e 's/\x74\x11\xe8\x21\x23\x00\x00/\xeb\x11\xe8\x21\x23\x00\x00/g' $out/bin/resolve
        ${lib.getExe pkgs.perl} -pi -e 's/\x03\x00\x89\x45\xFC\x83\x7D\xFC\x00\x74\x11\x48\x8B\x45\xC8\x8B/\x03\x00\x89\x45\xFC\x83\x7D\xFC\x00\xEB\x11\x48\x8B\x45\xC8\x8B/' $out/bin/resolve
        ${lib.getExe pkgs.perl} -pi -e 's/\x74\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00/\xEB\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00/' $out/bin/resolve
        ${lib.getExe pkgs.perl} -pi -e 's/\x41\xb6\x01\x84\xc0\x0f\x84\xb0\x00\x00\x00\x48\x85\xdb\x74\x08\x45\x31\xf6\xe9\xa3\x00\x00\x00/\x41\xb6\x00\x84\xc0\x0f\x84\xb0\x00\x00\x00\x48\x85\xdb\x74\x08\x45\x31\xf6\xe9\xa3\x00\x00\x00/' $out/bin/resolve
        touch $out/.license/blackmagic.lic
        echo -e "LICENSE blackmagic davinciresolvestudio 999999 permanent uncounted\n  hostid=ANY issuer=CGP customer=CGP issued=28-dec-2023\n  akey=0000-0000-0000-0000 _ck=00 sig=\"00\"" > $out/.license/blackmagic.lic

        mkdir -p $out/IOPlugins/ffmpeg_encoder_plugin.dvcp.bundle/Contents/Linux-x86-64/
        cp ${ffmpeg-encoder-plugin}/ffmpeg_encoder_plugin.dvcp $out/IOPlugins/ffmpeg_encoder_plugin.dvcp.bundle/Contents/Linux-x86-64/
      '';
    });
  in
    # the following was copied from davinci's derivation from nixpkgs.
    # if davinci updates, this should be updated too
    # but remember to replace "davinci" with "davinci-patched"
    pkgs.buildFHSEnv {
      inherit (davinci-patched) pname version;

      targetPkgs = pkgs:
        with pkgs;
          [
            alsa-lib
            aprutil
            bzip2
            dbus
            expat
            fontconfig
            freetype
            glib
            libGL
            libGLU
            libarchive
            libcap
            librsvg
            libtool
            libuuid
            libxcrypt # provides libcrypt.so.1
            libxkbcommon
            nspr
            ocl-icd
            opencl-headers
            python3
            python3.pkgs.numpy
            udev
            xdg-utils # xdg-open needed to open URLs
            xorg.libICE
            xorg.libSM
            xorg.libX11
            xorg.libXcomposite
            xorg.libXcursor
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXi
            xorg.libXinerama
            xorg.libXrandr
            xorg.libXrender
            xorg.libXt
            xorg.libXtst
            xorg.libXxf86vm
            xorg.libxcb
            xorg.xcbutil
            xorg.xcbutilimage
            xorg.xcbutilkeysyms
            xorg.xcbutilrenderutil
            xorg.xcbutilwm
            xorg.xkeyboardconfig
            zlib
          ]
          ++ [davinci-patched];

      extraPreBwrapCmds = ''
        mkdir -p ~/.local/share/DaVinciResolve/Extras || exit 1
        mkdir -p ~/.local/share/DaVinciResolve/logs || exit 1
        mkdir -p ~/.local/share/DaVinciResolve/configs || exit 1
      '';

      extraBwrapArgs = [
        ''--bind "$HOME"/.local/share/DaVinciResolve/Extras ${davinci-patched}/Extras''
      ];

      runScript = "${lib.getExe pkgs.bash} ${pkgs.writeText "davinci-wrapper" ''
        export QT_QPA_PLATFORM=xcb
        export QT_XKB_CONFIG_ROOT="${pkgs.xkeyboard_config}/share/X11/xkb"
        export QT_PLUGIN_PATH="${davinci-patched}/libs/plugins:$QT_PLUGIN_PATH"
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/lib32:${davinci-patched}/libs
        ${davinci-patched}/bin/resolve
      ''}";

      extraInstallCommands = ''
        mkdir -p $out/share/applications $out/share/icons/hicolor/128x128/apps
        ln -s ${davinci-patched}/share/applications/*.desktop $out/share/applications/
        ln -s ${davinci-patched}/graphics/DV_Resolve.png $out/share/icons/hicolor/128x128/apps/davinci-resolve-studio.png
      '';

      passthru = {
        inherit davinci-patched;
        updateScript = lib.getExe (
          pkgs.writeShellApplication {
            name = "update-davinci-resolve";
            runtimeInputs = [
              pkgs.curl
              pkgs.jq
              pkgs.common-updater-scripts
            ];
            text = ''
              set -o errexit
              drv=pkgs/by-name/da/davinci-resolve/package.nix
              currentVersion=${lib.escapeShellArg davinci-patched.version}
              downloadsJSON="$(curl --fail --silent https://www.blackmagicdesign.com/api/support/us/downloads.json)"

              latestLinuxVersion="$(echo "$downloadsJSON" | jq '[.downloads[] | select(.urls.Linux) | .urls.Linux[] | select(.downloadTitle | test("DaVinci Resolve")) | .downloadTitle]' | grep -oP 'DaVinci Resolve \K\d+\.\d+(\.\d+)?' | sort | tail -n 1)"
              update-source-version davinci-resolve "$latestLinuxVersion" --source-key=davinci.src

              # Since the standard and studio both use the same version we need to reset it before updating studio
              sed -i -e "s/""$latestLinuxVersion""/""$currentVersion""/" "$drv"

              latestStudioLinuxVersion="$(echo "$downloadsJSON" | jq '[.downloads[] | select(.urls.Linux) | .urls.Linux[] | select(.downloadTitle | test("DaVinci Resolve")) | .downloadTitle]' | grep -oP 'DaVinci Resolve Studio \K\d+\.\d+(\.\d+)?' | sort | tail -n 1)"
              update-source-version davinci-resolve-studio "$latestStudioLinuxVersion" --source-key=davinci.src
            '';
          }
        );
      };
    };
in {
  options.davinci.enable = lib.mkEnableOption "enable davinci resolve";
  config.environment.systemPackages = lib.mkIf config.davinci.enable [davinci-resolve-studio-cracked];

  # following configuration was taken from
  # https://wiki.nixos.org/wiki/DaVinci_Resolve

  # Zynix
}
