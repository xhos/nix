{
  config,
  lib,
  inputs,
  ...
}: {
  options.homelab.nagomi.enable = lib.mkEnableOption "nagomi finance tracker";

  imports = [inputs.nagomi.nixosModules.default];

  config = lib.mkIf config.homelab.nagomi.enable {
    services.nagomi = {
      enable = true;
      emailParser.enable = true;
      secretsFile = config.sops.secrets."env/nagomi/shared".path;
      core.secretsFile = config.sops.secrets."env/nagomi/core".path;
      gateway.secretsFile = config.sops.secrets."env/nagomi/gateway".path;
      gateway.url = "https://api.nagomi.${config.homelab.config.domain}";
      gateway.trustedOrigins = ["https://nagomi.${config.homelab.config.domain}"];
      gateway.cookieDomain = ".${config.homelab.config.domain}";
      emailParser.domain = "mail.nagomi.${config.homelab.config.domain}";
      # TLS for SMTP — reuse the ACME wildcard cert
      # emailParser.tls.certFile = "/path/to/fullchain.pem";
      # emailParser.tls.keyFile = "/path/to/privkey.pem";
      receipts.provider = "gemini";
      receipts.secretsFile = config.sops.secrets."env/nagomi/receipts".path;
    };

    sops.secrets."env/nagomi/shared" = {}; # API_KEY (loaded by core + email-parser)
    sops.secrets."env/nagomi/core" = {}; # CREDENTIALS_KEY
    sops.secrets."env/nagomi/gateway" = {}; # BETTER_AUTH_SECRET
    sops.secrets."env/nagomi/receipts" = {}; # GOOGLE_API_KEY

    persist.dirs = ["/var/lib/nagomi"];

    # homelab wiring — web frontend public, gateway public (API), SMTP forwarded
    homelab.exposedServices.nagomi.port = config.services.nagomi.web.port;
    homelab.exposedServices."api.nagomi".port = config.services.nagomi.gateway.port;
    homelab.tcpForwards.smtp = {
      listen = 25;
      port = config.services.nagomi.emailParser.smtpPort;
    };
  };
}
