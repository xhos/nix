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
      contentDir = "/storage/assetto/content";
      track = "shutoko_revival_project_094_ptb1";
      trackLayout = "main_layout";
      trafficSpline = "/storage/assetto/splines/srp-094ptb1-plot3sale-v6.aip";
      maxPlayers = 8;
      downloadSpeedLimit = 0;

      playerCars = lib.genAttrs [
        # rx-7
        "bati_fd3s_rx7"
        "art_mazda_fd3s_rx7_black_eagle"
        "rize_efini_rx7_fd3s_keisuke_1"
        "wm_mazda_rx7_fd_rgo"
        "ddm_mazda_fc3s_re"
        "ddm_mazda_rx7_infini_fc3s"
        # supra
        "ddm_toyota_supra_ma70"
        "naz_jza80_ridox_modern"
        "sl_toyota_supra_mkiv_ridox"
        "gmp_abflug_s900"
        "srp_toyota_supra_mkiv_interceptor"
        # gt-r
        "art_skyline_r32_gtr"
        "ddm_nissan_skyline_bnr32"
        "art_nissan_gtr_bcnr33_600r"
        "srp_bcnr33_wangan"
        "bksy_nissan_skyline_r34_vspec"
        "bksy_nissan_skyline_r34_vspec_ii_nur"
        "nissan_skyline_r34_omori_factory_s1"
        "nissan_skyline_r34_v-specperformance"
        "ks_nissan_gtr_boss"
        "ks_nissan_gtr_boss_MAIN"
        # everything else
        "ddm_nissan_silvia_s15"
        "wm_nissan_s15"
        "pear_nissan_silvia_s13_wangan"
        "lk_nissan_180sx_96"
        "wm_nissan_fairlady_z_s30"
        "p3_mitsubishi_evo8"
        "srp_mitsubishi_evo_5_kai"
        "aegis_mitsubishi_lancer_evolution_v_gsr" # evo v "aeroblitz"
        "j8_mitsubishi_gto_twin_turbo_91_haru_spec"
        "ddm_honda_s2000_ap1"
        "j8_ae86_tuned_coupe"
        "ddm_toyota_mr2_sw20_shuto"
        "arch_ruf_ctr_1987"
        "slang_ferrari_f40"
        "art_diablo_gtr"
        "spear_lamborghini_lp640_veilside"
        "honda_acty_ha3"
        "snp_zhonghua_zidantou_wangan_spec"
      ] (_: 1);

      # ks_nissan_gtr_boss_MAIN ships unpacked data/ instead of data.acd, so the
      # server can't checksum its physics; all other cars are still checked
      extraCfg.IgnoreConfigurationErrors.MissingCarChecksums = true;

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
      ] (_: 4);
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
