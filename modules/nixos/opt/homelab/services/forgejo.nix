{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = config.homelab.config.domain;
  stateDir = config.services.forgejo.stateDir;
  customDir = config.services.forgejo.customDir;

  catppuccin = pkgs.fetchzip {
    url = "https://github.com/catppuccin/gitea/releases/download/v1.0.2/catppuccin-gitea.tar.gz";
    hash = "sha256-rZHLORwLUfIFcB6K9yhrzr+UwdPNQVSadsw6rg8Q7gs=";
    stripRoot = false;
  };
  accents = ["rosewater" "flamingo" "pink" "mauve" "red" "maroon" "peach" "yellow" "green" "teal" "sky" "sapphire" "blue" "lavender"];
in {
  options.homelab.forgejo.enable = lib.mkEnableOption "forgejo git forge";

  config = lib.mkIf config.homelab.forgejo.enable {
    homelab.exposedServices.git = {
      port = 3030;
      name = "forgejo";
      exposed = true;
      dashboard = {
        group = "personal";
        icon = "sh:forgejo";
      };
    };

    # db is covered by the postgres dump; this holds repos and the key encrypting mirror creds
    persist.dirs = [stateDir];
    homelab.backup.services.forgejo = {
      paths = [stateDir];
      exclude = ["${stateDir}/log" "${stateDir}/data/repo-archive"];
    };

    # github push mirrors are per repo, set up in repo settings -> mirror
    services.forgejo = {
      enable = true;
      database.type = "postgres";
      lfs.enable = true;

      settings = {
        server = {
          DOMAIN = "git.${domain}";
          ROOT_URL = "https://git.${domain}/";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 3030;
          LANDING_PAGE = "/xhos";

          # built-in sshd on the tailnet only, host sshd never sees git traffic
          START_SSH_SERVER = true;
          BUILTIN_SSH_SERVER_USER = "git";
          SSH_DOMAIN = "${config.networking.hostName}.ts.${domain}";
          SSH_PORT = 2222;
          SSH_LISTEN_PORT = 2222;
        };

        service = {
          DISABLE_REGISTRATION = true;
          DEFAULT_KEEP_EMAIL_PRIVATE = true;
        };
        # memory sessions log you out on every rebuild
        session.PROVIDER = "db";
        # runners live on magi, `uses: actions/checkout@v4` resolves against github
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };

        # public instance: no version leak, no third-party avatar requests
        other.SHOW_FOOTER_VERSION = false;
        api.ENABLE_SWAGGER = false;
        picture = {
          DISABLE_GRAVATAR = true;
          ENABLE_FEDERATED_AVATAR = false;
        };

        "cron.git_gc_repos".ENABLED = true;

        ui = {
          DEFAULT_THEME = "catppuccin-mocha-mauve";
          THEMES = lib.concatStringsSep "," (["forgejo-auto" "forgejo-light" "forgejo-dark"] ++ map (a: "catppuccin-mocha-${a}") accents);
        };
      };
    };

    # crawlers walking every commit are expensive, discovery happens on github
    systemd.tmpfiles.rules = [
      "d '${customDir}/public' 0750 forgejo forgejo - -"
      "d '${customDir}/public/assets' 0750 forgejo forgejo - -"
      "L+ '${customDir}/public/assets/css' - - - - ${catppuccin}"
      "L+ '${customDir}/public/robots.txt' - - - - ${pkgs.writeText "robots.txt" ''
        User-agent: *
        Disallow: /
      ''}"
    ];
  };
}
