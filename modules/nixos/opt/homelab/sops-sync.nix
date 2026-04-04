{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  options.homelab.sops-sync.enable = lib.mkEnableOption "sync sops secrets to proton pass (pass-cli must be authed imperativly)";

  config = let
    sops-proton-pass-sync = pkgs.fetchFromGitHub {
      owner = "xhos";
      repo = "sops-proton-pass-sync";
      rev = "076ce0a475514a5751859fa84d37487c343c60f4";
      hash = "sha256-8P3CC1+KAFNKy38vBgQyqspi9n16zFmQIGPG6kY8RSg=";
    };
  in
    (lib.mkIf config.homelab.sops-sync.enable) {
      systemd.services.sops-proton-pass-sync = {
        description = "sync sops secrets to proton pass";
        after = ["network-online.target"];
        wants = ["network-online.target"];

        serviceConfig = {
          Type = "oneshot";
          User = "xhos";
          ExecStart = "${sops-proton-pass-sync}/sops-proton-pass-sync.sh ${toString inputs.nix-secrets}/secrets.yaml";
        };

        # im having issues with proton-pass-cli accessing the kernel keyring,
        # might be a bug, this fixes it for now.
        environment.PROTON_PASS_KEY_PROVIDER = "fs";

        path = with pkgs; [
          bash
          sops
          jq
          coreutils
          proton-pass-cli
        ];
      };

      systemd.timers.sops-proton-pass-sync = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };
    };
}
