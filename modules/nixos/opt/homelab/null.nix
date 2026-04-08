{
  config,
  lib,
  ...
}: {
  options.homelab.null.enable = lib.mkEnableOption "enable null";

  config = lib.mkIf config.homelab.null.enable {
    homelab.exposedServices."null".port = 55554;
    homelab.exposedServices."api.null".port = 55555;
    homelab.exposedServices."mcp.null".port = 55553;
    homelab.exposedServices."gateway.null".port = 55550;
    homelab.exposedServices."grafana.null".port = 56000;
  };
}
