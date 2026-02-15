{
  inputs,
  pkgs,
  ...
}: let
  sopsFolder = toString inputs.nix-secrets;

  sops-proton-pass-sync = pkgs.fetchFromGitHub {
    owner = "xhos";
    repo = "sops-proton-pass-sync";
    rev = "c2a19f39a0a600c76e934a34fac1b172b39cb3b5";
    hash = "sha256-wWuVf7PgyGZMts7F4Xxne+maoudHjILXerAAmKqwwNI=";
  };
in {
  systemd.services.sops-proton-pass-sync = {
    description = "sync sops secrets to proton pass";
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
      User = "xhos";
      ExecStart = "${sops-proton-pass-sync}/sops-proton-pass-sync.sh ${sopsFolder}/secrets.yaml";
    };

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
}
