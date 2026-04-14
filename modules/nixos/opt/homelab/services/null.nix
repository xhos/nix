{
  config,
  lib,
  inputs,
  ...
}: {
  options.homelab.null.enable = lib.mkEnableOption "null finance tracker";

  imports = [inputs.null.nixosModules.default];

  config = lib.mkIf config.homelab.null.enable {
    services.null = {
      enable = true;
      emailParser.enable = true;
      secretsFile = config.sops.secrets."env/null/shared".path;
      gateway.secretsFile = config.sops.secrets."env/null/gateway".path;
      gateway.url = "https://api.null.${config.homelab.config.domain}";
      gateway.trustedOrigins = ["https://null.${config.homelab.config.domain}"];
      gateway.cookieDomain = ".${config.homelab.config.domain}";
      emailParser.domain = "mail.null.${config.homelab.config.domain}";
      # TLS for SMTP — reuse the ACME wildcard cert
      # emailParser.tls.certFile = "/path/to/fullchain.pem";
      # emailParser.tls.keyFile = "/path/to/privkey.pem";
      receipts.provider = "gemini";
      receipts.secretsFile = config.sops.secrets."env/null/receipts".path;
    };

    sops.secrets."env/null/shared" = {};    # API_KEY (loaded by core + email-parser)
    sops.secrets."env/null/gateway" = {};   # BETTER_AUTH_SECRET
    sops.secrets."env/null/receipts" = {};  # GOOGLE_API_KEY

    persist.dirs = ["/var/lib/null"];

    # homelab wiring — web frontend public, gateway public (API), SMTP forwarded
    homelab.exposedServices.null = {
      port = config.services.null.web.port;
      exposed = true;
    };
    homelab.exposedServices."api.null" = {
      port = config.services.null.gateway.port;
      subdomain = "api.null";
      exposed = true;
    };
    homelab.tcpForwards.smtp = {
      listen = 25;
      port = config.services.null.emailParser.smtpPort;
    };
  };
}
