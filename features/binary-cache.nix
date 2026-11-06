{inputs, ...}: let
  server = "enrai.ts.xhos.dev";
  niksPort = 5751;
  tokenSecret = "cache/niks3-token";
in {
  flake.modules.nixos.garage = {
    config,
    pkgs,
    ...
  }: {
    sops.secrets."env/garage".restartUnits = ["garage.service"];

    users.users.garage = {
      isSystemUser = true;
      group = "garage";
    };
    users.groups.garage = {};

    # static user keeps the data out of /var/lib/private
    systemd.services.garage.serviceConfig = {
      DynamicUser = false;
      User = "garage";
      Group = "garage";
    };

    # separate unit: garage's ReadWritePaths fail every exec, even "+", until these exist
    systemd.services.garage-dirs = {
      before = ["garage.service"];
      requiredBy = ["garage.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/install -d -o garage -g garage -m 0700 /persist/garage /persist/garage/meta /persist/garage/data";
      };
    };

    networking.firewall.interfaces = {
      lan0.allowedTCPPorts = [3901];
      tailscale0.allowedTCPPorts = [3900 3902];
    };

    services.garage = {
      enable = true;
      package = pkgs.garage_2;
      environmentFile = config.sops.secrets."env/garage".path;
      settings = {
        metadata_dir = "/persist/garage/meta";
        data_dir = "/persist/garage/data";

        replication_factor = 1;
        compression_level = "none"; # nars are already zstd

        rpc_bind_addr = "0.0.0.0:3901";
        s3_api = {
          api_bind_addr = "0.0.0.0:3900";
          s3_region = "garage";
        };
        s3_web = {
          bind_addr = "0.0.0.0:3902";
          root_domain = ".web.garage";
        };
      };
    };
  };

  flake.modules.nixos.niks3 = {config, ...}: {
    imports = [inputs.niks3.nixosModules.niks3];

    sops.secrets = {
      ${tokenSecret}.owner = "niks3";
      "cache/signing-key".owner = "niks3";
      "cache/s3-access-key".owner = "niks3";
      "cache/s3-secret-key".owner = "niks3";
    };

    services.niks3 = {
      enable = true;
      httpAddr = "0.0.0.0:${toString niksPort}";
      apiTokenFile = config.sops.secrets.${tokenSecret}.path;
      signKeyFiles = [config.sops.secrets."cache/signing-key".path];
      s3 = {
        # presigned urls are bound to this host, so every pusher has to reach it
        endpoint = "${server}:3900";
        bucket = "cache";
        region = "garage";
        useSSL = false;
        bucketLookup = "path";
        accessKeyFile = config.sops.secrets."cache/s3-access-key".path;
        secretKeyFile = config.sops.secrets."cache/s3-secret-key".path;
      };
    };
  };

  flake.modules.nixos.niks3-push = {config, ...}: {
    imports = [inputs.niks3.nixosModules.niks3-auto-upload];

    sops.secrets.${tokenSecret} = {};

    services.niks3-auto-upload = {
      enable = true;
      serverUrl = "http://${server}:${toString niksPort}";
      authTokenFile = config.sops.secrets.${tokenSecret}.path;
    };
  };
}
