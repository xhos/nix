{
  pkgs,
  virtualDesktop ? false,
  dpi ? 96,
}:
pkgs.mkWindowsAppNoCC rec {
  pname = "adobe-acrobat-reader";
  version = "2025.1.20997";

  wine = pkgs.winePackages.stableFull;
  wineArch = "win32";

  src = pkgs.fetchurl {
    url = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2500120997/AcroRdrDC2500120997_en_US.exe";
    hash = "sha256-gznoj4yY9Fktz8LVWhjBwArUqSlQOUX9/r6ukojATG8=";
  };

  dontUnpack = true;
  persistRegistry = false;
  persistRuntimeLayer = true;
  enableMonoBootPrompt = false;
  graphicsDriver = "auto";

  nativeBuildInputs = [pkgs.copyDesktopItems];

  enabledWineSymlinks = {
    desktop = false;
  };

  fileMap = {
    "$HOME/.config/adobe-acrobat-reader/Local" = "drive_c/users/$USER/AppData/Local/Adobe";
    "$HOME/.config/adobe-acrobat-reader/LocalLow" = "drive_c/users/$USER/AppData/LocalLow/Adobe";
    "$HOME/.config/adobe-acrobat-reader/Roaming" = "drive_c/users/$USER/AppData/Roaming/Adobe";
  };

  regTweaks = pkgs.fetchurl {
    url = "https://aur.archlinux.org/cgit/aur.git/plain/acroread-dc.reg?h=acroread-dc-wine";
    hash = "sha256-EXFuBh+altFKojYtrrviQkLi5LFCFeGo2VPhfNFlvj4=";
  };

  winAppInstall = ''
    export WINEDEBUG="-all"
    work="$(mktemp -d)"

    winetricks --unattended mspatcha
    winetricks --unattended riched20
    winetricks --unattended vcrun2015

    ${pkgs.p7zip}/bin/7z x -y -o"$work" ${src}
    setup="$(find "$work" -maxdepth 2 -iname 'setup.exe' | head -n1)"
    if [ -n "$setup" ]; then
      $WINE "$setup" /sAll
      wineserver -w
    else
      echo "Acrobat setup.exe not found in extracted files" >&2
      exit 1
    fi

    regfile="$WINEPREFIX/drive_c/acroread-dc.reg"
    cp ${regTweaks} "$regfile"
    $WINE regedit "$($WINE winepath -w "$regfile")"
    wineserver -w

    winetricks --unattended win7

    winetricks --unattended cjkfonts
  '';

  winAppRun = ''
    export WINEDEBUG="-all"
    reader="$WINEPREFIX/drive_c/Program Files (x86)/Adobe/Acrobat Reader DC/Reader/AcroRd32.exe"
    if [ ! -f "$reader" ]; then
      reader="$WINEPREFIX/drive_c/Program Files/Adobe/Acrobat Reader DC/Reader/AcroRd32.exe"
    fi
    if [ ! -f "$reader" ]; then
      echo "Adobe Acrobat Reader executable not found in Wine prefix" >&2
      exit 1
    fi

    # acrobat reads DPI at startup, so this has to land before the exec. it
    # writes into the persisted runtime layer, hence no reinstall on retune —
    # but changing this file at all does rebuild the app layer, see below.
    $WINE reg add "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d "''${ACROREAD_DPI:-${toString dpi}}" /f

    if ${
      if virtualDesktop
      then "true"
      else "false"
    } && [ "''${ACROREAD_NO_VIRTUAL_DESKTOP:-0}" != "1" ]; then
      res="$(${pkgs.xrandr}/bin/xrandr 2>/dev/null | ${pkgs.gawk}/bin/awk '/\\*/ && $1 ~ /^[0-9]+x[0-9]+$/ {print $1; exit}')"
      if [ -z "$res" ]; then
        res="1920x1080"
      fi
      $WINE explorer /desktop=AcroRead,"$res" "$reader" "$ARGS"
    else
      $WINE reg add "HKCU\Software\Wine\X11 Driver" /v Decorated /t REG_SZ /d N /f
      $WINE "$reader" "$ARGS"
    fi
  '';

  installPhase = ''
    runHook preInstall

    mv $out/bin/.launcher $out/bin/${pname}

    runHook postInstall
  '';

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = pname;
      exec = pname;
      icon = "application-pdf";
      desktopName = "Adobe Acrobat Reader DC";
      categories = [
        "Office"
        "Viewer"
      ];
    })
  ];

  meta = with pkgs.lib; {
    description = "Adobe Acrobat Reader DC - PDF viewer (via Wine)";
    homepage = "https://www.adobe.com/products/reader.html";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "adobe-acrobat-reader";
  };
}
