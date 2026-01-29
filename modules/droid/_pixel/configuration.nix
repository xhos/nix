{
  pkgs,
  config,
  inputs,
  ...
}: let
  sshdTmpDirectory = "${config.user.home}/sshd-tmp";
  sshdDirectory = "${config.user.home}/sshd";
  port = 8022;

  # Path to your sops secrets file
  secretsFile = "${inputs.nix-secrets}/secrets.yaml";

  # Helper to extract and decrypt a secret
  extractSecret = name: output: ''
    if [[ -f ${secretsFile} ]]; then
      $VERBOSE_ECHO "Decrypting ${name}..."
      $DRY_RUN_CMD ${pkgs.sops}/bin/sops -d --extract '["${name}"]' ${secretsFile} > "${output}"
      $DRY_RUN_CMD chmod 600 "${output}"
    else
      echo "Warning: secrets file not found at ${secretsFile}"
    fi
  '';
in {
  environment.packages = with pkgs; [
    iproute2
    vim
    procps
    killall
    diffutils
    findutils
    utillinux
    tzdata
    hostname
    man
    gnugrep
    gnupg
    gnused
    gnutar
    bzip2
    gzip
    xz
    zip
    unzip
    inputs.swissh.packages."${pkgs.stdenv.hostPlatform.system}".default

    (pkgs.writeScriptBin "sshd-start" ''
      #!${pkgs.runtimeShell}
      echo "Starting sshd on port ${toString port}"
      ${pkgs.openssh}/bin/sshd -f "${sshdDirectory}/sshd_config" -D
    '')
  ];

  build.activation.sshd = ''
        $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${config.user.home}/.ssh"
        $DRY_RUN_CMD cat ${./pixel.pub} > "${config.user.home}/.ssh/authorized_keys"
        $DRY_RUN_CMD chmod 600 "${config.user.home}/.ssh/authorized_keys"

        if [[ ! -d "${sshdDirectory}" ]]; then
          $DRY_RUN_CMD rm $VERBOSE_ARG --recursive --force "${sshdTmpDirectory}"
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${sshdTmpDirectory}"

          $VERBOSE_ECHO "Generating host keys..."
          $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -f "${sshdTmpDirectory}/ssh_host_rsa_key" -N ""

          $VERBOSE_ECHO "Writing sshd_config..."
          $DRY_RUN_CMD cat > "${sshdTmpDirectory}/sshd_config" <<EOF
    HostKey ${sshdDirectory}/ssh_host_rsa_key
    Port ${toString port}
    PasswordAuthentication no
    PubkeyAuthentication yes
    PermitRootLogin no
    StreamLocalBindUnlink yes
    GatewayPorts clientspecified
    EOF

          $DRY_RUN_CMD mv $VERBOSE_ARG "${sshdTmpDirectory}" "${sshdDirectory}"
        fi
  '';

  # Decrypt SSH keys from sops
  build.activation.decrypt-secrets = ''
    SECRETS_DIR="${config.user.home}/.ssh"
    $DRY_RUN_CMD mkdir -p "$SECRETS_DIR"

    ${extractSecret "ssh/proxy" "$SECRETS_DIR/proxy"}
    ${extractSecret "ssh/monitor" "$SECRETS_DIR/monitor"}
    ${extractSecret "ssh/vault" "$SECRETS_DIR/vault"}
    ${extractSecret "ssh/mc" "$SECRETS_DIR/mc"}
    ${extractSecret "ssh/vyverne" "$SECRETS_DIR/vyverne"}
    ${extractSecret "ssh/enrai" "$SECRETS_DIR/enrai"}
    ${extractSecret "ssh/github" "$SECRETS_DIR/github"}
  '';

  environment.etcBackupExtension = ".bak";

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Home-manager configuration
  home-manager = {
    config = {
      home.stateVersion = "24.05";

      # GitHub public key (not secret)
      home.file.".ssh/github.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgRlG4m4RWFLHarzFFG5Q4MRyZK737laibKI42aUNhF";

      programs.ssh = {
        enable = true;
        matchBlocks = {
          # git
          "github" = {
            host = "github.com";
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/github";
          };
          # VPS
          "proxy-1" = {
            host = "proxy-1";
            hostname = "40.233.88.40";
            user = "root";
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/proxy";
          };
          "proxy-2" = {
            host = "proxy-2";
            hostname = "89.168.83.242";
            user = "root";
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/proxy";
          };
          "monitor" = {
            host = "monitor";
            hostname = "40.233.127.68";
            user = "root";
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/monitor";
          };
          "vault" = {
            host = "vault";
            hostname = "40.233.74.249";
            user = "ubuntu";
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/vault";
          };
          # VM
          "mc" = {
            host = "mc";
            hostname = "xhos.dev";
            port = 2222;
            user = "mc";
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/mc";
          };
          # bare metal
          "vyverne" = {
            host = "vyverne";
            hostname = "10.0.0.11";
            user = "xhos";
            port = 10022;
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/vyverne";
          };
          "enrai" = {
            host = "enrai";
            hostname = "10.0.0.10";
            user = "xhos";
            port = 10022;
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/enrai";
          };
          "enrai-t" = {
            host = "enrai-t";
            hostname = "ssh.xhos.dev";
            user = "xhos";
            port = 10022;
            identitiesOnly = true;
            identityFile = "${config.user.home}/.ssh/enrai";
            proxyCommand = "cloudflared access ssh --hostname %h";
          };
        };
      };
    };

    backupFileExtension = "backup";
    useGlobalPkgs = true;
  };

  system.stateVersion = "24.05";
}
