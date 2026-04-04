{config, ...}: {
  sops.secrets = {
    "ssh/proxy".mode = "0600";
    "ssh/mizore".mode = "0600";
    "ssh/arashi".mode = "0600";
    "ssh/mc".mode = "0600";
    "ssh/vyverne".mode = "0600";
    "ssh/enrai".mode = "0600";
    "ssh/github" = {
      path = "${config.home.homeDirectory}/.ssh/github";
      mode = "0600";
    };
  };

  # git needs this sometimes
  home.file."${config.home.homeDirectory}/.ssh/github.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgRlG4m4RWFLHarzFFG5Q4MRyZK737laibKI42aUNhF";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      # git
      "github" = {
        host = "github.com";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/github".path;
      };
      # VPS
      "proxy-1" = {
        host = "proxy-1";
        hostname = "40.233.109.227";
        user = "xhos";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/proxy".path;
      };
      "proxy-2" = {
        host = "proxy-2";
        hostname = "89.168.83.242";
        user = "root";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/proxy".path;
      };
      "mizore" = {
        host = "mizore";
        hostname = "40.233.96.175";
        user = "xhos";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/mizore".path;
      };
      "arashi" = {
        host = "arashi";
        hostname = "40.233.119.97";
        user = "xhos";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/arashi".path;
      };
      # VM
      "mc" = {
        host = "mc";
        hostname = "xhos.dev";
        port = 2222;
        user = "mc";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/mc".path;
      };
      # bare metal
      "vyverne" = {
        host = "vyverne";
        hostname = "10.0.0.11";
        user = "xhos";
        port = 22;
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/vyverne".path;
      };
      "enrai" = {
        host = "enrai";
        hostname = "10.0.0.10";
        user = "xhos";
        port = 22;
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/enrai".path;
      };
    };
  };
}
