{
  flake.modules.homeManager.obs = {
    config,
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    profile = "Untitled";
    obsDir = "${config.xdg.configHome}/obs-studio";

    # obs rewrites these files, so declared keys are merged in and the rest stays mutable
    merge = pkgs.writeText "obs-merge.py" ''
      import configparser, json, pathlib, sys

      base = pathlib.Path(sys.argv[1])
      for rel, sections in json.load(open(sys.argv[2])).items():
          path = base / rel
          ini = configparser.RawConfigParser(delimiters=("=",), comment_prefixes=(), strict=False)
          ini.optionxform = str
          ini.read(path, encoding="utf-8")
          for section, keys in sections.items():
              if not ini.has_section(section):
                  ini.add_section(section)
              for key, value in keys.items():
                  ini[section][key] = str(value).lower() if isinstance(value, bool) else str(value)
          path.parent.mkdir(parents=True, exist_ok=True)
          with open(path, "w", encoding="utf-8") as f:
              ini.write(f, space_around_delimiters=False)
    '';

    settings = pkgs.writeText "obs-settings.json" (builtins.toJSON {
      "user.ini" = {
        General = {
          FirstRun = true;
          ConfirmOnExit = true;
          HotkeyFocusType = "NeverDisableHotkeys";
        };
        BasicWindow.PreviewEnabled = false;
        Basic = {
          Profile = profile;
          ProfileDir = profile;
        };
        Appearance = {
          FontScale = 10;
          Density = -4;
        };
      };

      "basic/profiles/${profile}/basic.ini" = {
        General.Name = profile;
        Output.Mode = "Advanced";
        AdvOut = {
          RecFilePath = "${config.home.homeDirectory}/Videos/obs";
          RecFormat2 = "hybrid_mp4";
          # hidden from the ui, but the _tex encoder's gl-cuda path stalls the renderer
          # so badly here that replay saves never complete
          RecEncoder = "obs_nvenc_h264_soft";
          AudioEncoder = "libfdk_aac";
          RecAudioEncoder = "libfdk_aac";
        };
        Video = {
          BaseCX = 1920;
          BaseCY = 1080;
          OutputCX = 1920;
          OutputCY = 1080;
          FPSCommon = 60;
        };
      };
    });

    recordEncoder = pkgs.writeText "obs-record-encoder.json" (builtins.toJSON {
      rate_control = "CBR";
      bitrate = 12000;
      keyint_sec = 2;
      preset = "p3";
      tune = "ll";
      multipass = "disabled";
      lookahead = false;
      adaptive_quantization = false;
    });

  in {
    programs.obs-studio = {
      enable = true;
      # nvenc needs libnvidia-encode, which the default build can't find
      package = lib.mkIf (osConfig.nvidia.enable or false) (pkgs.obs-studio.override {cudaSupport = true;});
    };

    persist.dirs = [".config/obs-studio"];

    home.activation.obsSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.python3}/bin/python3 -I ${merge} ${obsDir} ${settings}
      run install -Dm644 ${recordEncoder} ${obsDir}/basic/profiles/${profile}/recordEncoder.json
    '';
  };
}
