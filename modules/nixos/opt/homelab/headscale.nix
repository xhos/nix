# headscale.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.homelab.headscale.enable = lib.mkEnableOption "run headscale control plane (should be one of these in the network)";

  config = lib.mkIf config.homelab.headscale.enable (let
    domain = config.homelab.config.domain;
    hs = config.services.headscale;
    recordsPath = "/var/lib/headscale/extra-records.json";

    homelabHosts =
      lib.filterAttrs (
        name: cfg: name != "proxy-1" && (cfg.config.homelab.enable or false)
      )
      inputs.self.nixosConfigurations;

    # internal service fqdn -> node name, for every non-exposed service
    recordHosts = pkgs.writeText "extra-record-hosts.json" (builtins.toJSON (lib.listToAttrs (lib.flatten (
      lib.mapAttrsToList (
        _: cfg:
          lib.mapAttrsToList (svcName: svc:
            lib.nameValuePair "${
              if svc.subdomain != ""
              then svc.subdomain
              else svcName
            }.${domain}"
            cfg.config.networking.hostName)
          (lib.filterAttrs (_: s: !s.exposed) cfg.config.homelab.exposedServices)
      )
      homelabHosts
    ))));
  in {
    homelab.exposedServices.headscale = {
      port = 8080;
      subdomain = "hs";
      exposed = true;
    };

    sops.secrets."vpn/headscale-identity".owner = config.services.headscale.user;

    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8080;
      settings = {
        noise.private_key_path = config.sops.secrets."vpn/headscale-identity".path;
        server_url = "https://hs.${domain}";
        ip_prefixes = ["100.64.0.0/10"];
        dns = {
          magic_dns = true;
          base_domain = "ts.${domain}";
          nameservers.global = ["1.1.1.1" "1.0.0.1"];

          # filled at runtime by headscale-extra-records, ips aren't known at build time
          extra_records_path = recordsPath;
        };
      };
    };

    # headscale refuses to start if the records file is missing
    systemd.services.headscale.preStart = ''
      [ -e ${recordsPath} ] || echo '[]' > ${recordsPath}
    '';

    # join "service -> host" from the flake with headscale's live node ips.
    # headscale watches the file and only pushes when the contents change
    systemd.services.headscale-extra-records = {
      description = "point internal service names at their hosts' tailnet ips";
      after = ["headscale.service"];
      requires = ["headscale.service"];
      wantedBy = ["headscale.service"];
      path = [hs.package pkgs.jq];
      serviceConfig = {
        Type = "oneshot";
        User = hs.user;
        Group = hs.group;
        # socket may not be up yet right after headscale starts
        Restart = "on-failure";
        RestartSec = "10s";
      };
      script = ''
        nodes=$(headscale --config ${hs.configFile} nodes list -o json)
        jq -n --argjson nodes "$nodes" --slurpfile want ${recordHosts} '
          [ $want[0] | to_entries[] as $r
            | ($nodes // [])[] | select(.given_name == $r.value)
            | .ip_addresses[] | select(contains(":") | not)
            | {Name: $r.key, Type: "A", Value: .} ]
        ' > ${recordsPath}.tmp
        mv ${recordsPath}.tmp ${recordsPath}
      '';
    };

    systemd.timers.headscale-extra-records = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1min";
      };
    };
  });
}
