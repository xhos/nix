{
  imports = [../magi/common.nix];

  # installer greps the host dir for this to put the sops key under /persist
  impermanence.enable = true;

  networking.hostName = "melchior";
  networking.hostId = "663898f4";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./melchior.pub];
}
