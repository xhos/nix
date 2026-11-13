{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.cliproxyapi;
  pkg = import ../../../../../pkgs/cliproxyapi.nix {inherit pkgs;};
  dir = "/var/lib/cliproxyapi";
  keySecret = client: "api/cliproxy/${client}";
in {
  options.homelab.cliproxyapi = {
    enable = lib.mkEnableOption "CLIProxyAPI, an OpenAI-compatible endpoint backed by the AI Pro sub";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8317;
    };
    clients = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["kodama" "nagomi"];
      description = "One api key per client, read from the sops secret api/cliproxy/<client>.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.cliproxyapi = {
      isSystemUser = true;
      group = "cliproxyapi";
      home = dir;
    };
    users.groups.cliproxyapi = {};

    sops.secrets = lib.genAttrs (map keySecret cfg.clients) (_: {});

    sops.templates."cliproxyapi.yaml" = {
      owner = "cliproxyapi";
      restartUnits = ["cliproxyapi.service"];
      content = lib.generators.toYAML {} {
        config-version = 8;
        server = {
          host = "127.0.0.1";
          inherit (cfg) port;
        };
        oauth.auth-dir = "${dir}/auth";
        access.api-keys = map (c: config.sops.placeholder.${keySecret c}) cfg.clients;
      };
    };

    # log in once: copy an antigravity-*.json from a dev `proxy login` into ${dir}/auth
    systemd.services.cliproxyapi = {
      description = "CLIProxyAPI";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      # it can write back to its config, so it gets a copy instead of the read-only template
      preStart = ''
        install -m 600 ${config.sops.templates."cliproxyapi.yaml".path} ${dir}/config.yaml
        mkdir -p ${dir}/auth
      '';
      serviceConfig = {
        ExecStart = "${pkg}/bin/cli-proxy-api -config ${dir}/config.yaml";
        User = "cliproxyapi";
        Group = "cliproxyapi";
        WorkingDirectory = dir;
        Restart = "always";
        RestartSec = 3;
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [dir];
      };
    };

    persist.dirs = [
      {
        directory = dir;
        user = "cliproxyapi";
        group = "cliproxyapi";
        mode = "0700";
      }
    ];

    # internal only: tailnet clients use https://llm.<domain>/v1, gated to owner + tag:server
    homelab.exposedServices.llm.port = cfg.port;
  };
}
