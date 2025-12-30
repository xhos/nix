{config, ...}: {
  sops.secrets = {
    "ssh/proxy".mode = "0600";
    "ssh/monitor".mode = "0600";
    "ssh/vault".mode = "0600";
    "ssh/mc".mode = "0600";
    "ssh/vyverne".mode = "0600";
    "ssh/enrai".mode = "0600";
    "ssh/github".mode = "0600"; # this is a bit of a chicken and egg problem, but i'll come up with a solution next time i re-install
    "ssh/azure".mode = "0600";
  };

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
      "azure" = {
        host = "ssh.dev.azure.com";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/azure".path;
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
      "monitor" = {
        host = "monitor";
        hostname = "40.233.127.68";
        user = "root";
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/monitor".path;
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
        port = 10022;
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/vyverne".path;
      };
      "enrai" = {
        host = "enrai";
        hostname = "10.0.0.10";
        user = "xhos";
        port = 10022;
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/enrai".path;
      };
      "enrai-t" = {
        host = "enrai-t";
        hostname = "ssh.xhos.dev";
        user = "xhos";
        port = 10022;
        identitiesOnly = true;
        identityFile = config.sops.secrets."ssh/enrai".path;
        proxyCommand = "cloudflared access ssh --hostname %h";
      };
    };
  };
}
