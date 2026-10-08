{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.vpn-confinement.nixosModules.default
    inputs.vscode-server.nixosModules.default
    ./hardware-configuration.nix
    ./disko.nix
    ./kodama.nix
  ];

  users.users.root.initialHashedPassword = "$y$j9T$iDTgP1si33HTwRpAPY2r1/$y1LJRFAgrqAgXhCH/Y/pvYu.X0snt306UZmoGksWhR4";
  networking.hostName = "enrai";
  networking.hostId = "8a1e0ee2";
  nixpkgs.hostPlatform = "x86_64-linux";

  impermanence.enable = true;
  profile = "full";

  homelab = {
    config.tailscaleIP = "100.64.0.5";

    enable = true;
    baremetal = {
      enable = true;
      interface = "enp0s31f6";
      gateway = "10.0.0.1";
    };

    docker.enable = true;
    tg-notify.enable = true;
    sops-sync.enable = true;

    valheim = {
      enable = true;
      code = "01a112f4-bb4e-33d8-a4b2-e55a815cac2f";
      hash = "sha256-bQcddpcShSrJVLhBLgNvLRyD5UbRApQ5q2oOUBN1fAo=";
      requirePassword = false;
      allowedInterfaces = ["zt*" "enp0s31f6"];
      modifiers.resources = "more"; # 1.5x
      admins = [
        "76561198866784053"
        "76561198174117583"
        "76561198246931306"
      ];
    };

    assetto-server.contentOwner = "xhos";
    assetto-server.instances.srp = {
      enable = true;
      public = true;
      # friends whose ISP won't do UDP to proxy-1 join over zerotier instead
      allowedInterfaces = ["zt*"];
      contentDir = "/storage/assetto/content";
      track = "shutoko_revival_project_094_ptb1";
      trackLayout = "main_layout";
      pitBoxes = 170;
      trafficSpline = "/storage/assetto/splines/srp-094ptb1-plot3sale-v6.aip";
      maxPlayers = 8;
      downloadSpeedLimit = 0;

      playerCars = lib.genAttrs [
        # what people actually drove
        "bati_fd3s_rx7"
        "art_mazda_fd3s_rx7_black_eagle"
        "sl_toyota_supra_mkiv_ridox"
        "ddm_nissan_silvia_s15"
        "wm_nissan_s15"
        "wm_nissan_fairlady_z_s30"
        "art_nissan_gtr_bcnr33_600r"
        "ks_nissan_gtr_boss_MAIN"
        # added 2026-09-28
        "dodge_viper17"
        "Arf_GR_86"
        "axis_s15_garagemak"
        "TRR_GT3_porsche_992_gt3_r"
        "acme_toyota_yaris_rally1_22_gravel"
      ] (_: 1);

      # ks_nissan_gtr_boss_MAIN, Arf_GR_86 and acme_toyota_yaris_rally1_22_gravel
      # ship unpacked data/ instead of data.acd, so the server can't checksum
      # their physics; all other cars are still checked
      extraCfg.IgnoreConfigurationErrors.MissingCarChecksums = true;
      extraCfg.AiParams = {
        MinAiSafetyDistanceMeters = 15;
        MaxAiSafetyDistanceMeters = 30;
        # Override the wider default spacing on one- and two-lane roads too.
        LaneCountSpecificOverrides = {
          "1" = {
            MinAiSafetyDistanceMeters = 20;
            MaxAiSafetyDistanceMeters = 35;
          };
          "2" = {
            MinAiSafetyDistanceMeters = 15;
            MaxAiSafetyDistanceMeters = 30;
          };
        };
      };
      # Freeroam: suppress false wrong-way penalties and control lockouts.
      serverCfg.SERVER.PENALTIES = false;
      cspExtraOptions.EXTRA_RULES = {
        ALLOW_WRONG_WAY = true;
        ENFORCE_BACK_TO_PITS_PENALTY = false;
        LIMIT_LOCK_CONTROLS_TIME = 0;
        LIMIT_LOCK_CONTROLS_TOTAL_TIME = 0;
      };

      trafficCars = lib.genAttrs [
        "traffic_aegis_toyota_prius"
        "traffic_aegis_toyota_markii_taxi"
        "traffic_aegis_suzuki_alto_works"
        "traffic_aegis_toyota_vellfire"
        "traffic_aegis_izuzu_npr_box"
        "traffic_aegis_ud_quon"
        "traffic_isuzu_tanker"
        "traffic_toyota_camry"
        "traffic_nissan_leaf"
        "traffic_volvo_v70jp"
      ] (_: 4)
      # 45 entries: one extra slot for the five most common models
      // lib.genAttrs [
        "traffic_aegis_toyota_prius"
        "traffic_aegis_toyota_markii_taxi"
        "traffic_aegis_suzuki_alto_works"
        "traffic_toyota_camry"
        "traffic_nissan_leaf"
      ] (_: 5);
    };

    atuin.enable = true;
    dawarich.enable = true;
    glance.enable = true;
    immich.enable = true;
    nagomi.enable = true;
    syncthing.enable = true;
    wakapi.enable = true;
    xray.enable = false;
    zipline.enable = false;
    home-assistant.enable = true;

    media = {
      servarr.enable = true;
      jellyfin.enable = true;
      prowlarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      qbittorrent = {
        enable = true;
        proton-vpn.enable = true;
      };
    };
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.vscode-server.enable = true;

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./enrai.pub];

  services.openssh.settings.AcceptEnv = lib.mkForce ["LANG" "LC_*"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # gaming lan with friends (assetto corsa server)
  services.zerotierone = {
    enable = true;
    joinNetworks = ["abfd31bd47fb27ef"];
  };
  persist.dirs = ["/var/lib/zerotier-one"];
  homelab.firewall.extraInputRules = ''
    udp dport 9993 accept
  '';

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # TODO: use disko nodev on next install
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=25%"
      "mode=755"
    ];
  };

  system.stateVersion = "25.05";
}
