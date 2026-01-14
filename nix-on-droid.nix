{
  pkgs,
  inputs,
  ...
}: {
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
  ];

  environment.etcBackupExtension = ".bak";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # nix.extraOptions = ''
  # experimental-features = nix-command flakes
  # '';

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./pixel.pub];

  system.stateVersion = "24.05";
}
