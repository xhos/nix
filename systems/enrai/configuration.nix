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
      # SRP 0.9.4 PTB1 srp_pits_main.kn5: Yoyogi is AC_PIT_41..61.
      # Keep main_layout for traffic capacity; player cars occupy slots 41..53.
      playerSlotOffset = 41;
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
        "aegis_mitsubishi_lancer_evolution_v_gsr" # evo v "aeroblitz"
        # something different
        "slang_ferrari_f40"
        "ddm_subaru_22b"
        "j8_ae86_tuned_coupe"
        "honda_acty_ha3"
      ] (_: 1);

      # ks_nissan_gtr_boss_MAIN ships unpacked data/ instead of data.acd, so the
      # server can't checksum its physics; all other cars are still checked
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
      ] (_: 6);
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
