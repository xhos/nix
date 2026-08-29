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
    settings = {
      # git
      "github.com" = {
        IdentitiesOnly = true;
        IdentityFile = config.sops.secrets."ssh/github".path;
      };
      # VPS
      "proxy-1" = {
        HostName = "40.233.109.227";
        User = "xhos";
        IdentitiesOnly = true;
        IdentityFile = config.sops.secrets."ssh/proxy".path;
      };
      "proxy-2" = {
        HostName = "89.168.83.242";
        User = "root";
        IdentitiesOnly = true;
        IdentityFile = config.sops.secrets."ssh/proxy".path;
      };
      "mizore" = {
        HostName = "40.233.96.175";
        User = "xhos";
        IdentitiesOnly = true;
        IdentityFile = config.sops.secrets."ssh/mizore".path;
      };
      "arashi" = {
        HostName = "40.233.119.97";
        User = "xhos";
        IdentitiesOnly = true;
        IdentityFile = config.sops.secrets."ssh/arashi".path;
      };
      # VM
      "mc" = {
        HostName = "xhos.dev";
        Port = 2222;
        User = "mc";
        IdentitiesOnly = true;
        IdentityFile = config.sops.secrets."ssh/mc".path;
      };
      # bare metal
      "vyverne" = {
        HostName = "10.0.0.11";
        User = "xhos";
        Port = 22;
        IdentitiesOnly = true;
        IdentityFile = config.sops.secrets."ssh/vyverne".path;
      };
      "enrai" = {
        HostName = "10.0.0.10";
        User = "xhos";
        Port = 22;
        IdentitiesOnly = true;
        IdentityFile = config.sops.secrets."ssh/enrai".path;
      };
    };
  };
}
