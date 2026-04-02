{config, ...}: {
  sops.secrets = {
    "ssh/proxy".mode = "0600";
    "ssh/null".mode = "0600";
    "ssh/vault".mode = "0600";
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
        hostname = "40.233.88.40";
        user = "root";
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
      "null" = {
        host = "null";
        hostname = "40.233.78.151";
        user = "root";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/null".path;
      };
      "vault" = {
        host = "vault";
        hostname = "40.233.74.249";
        user = "ubuntu";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/vault".path;
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
      "enrai-t" = {
        host = "enrai-t";
        hostname = "ssh.xhos.dev";
        user = "xhos";
        port = 22;
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/enrai".path;
        proxyCommand = "cloudflared access ssh --hostname %h";
      };
    };
  };
}
