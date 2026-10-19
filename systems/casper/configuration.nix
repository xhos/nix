{
  imports = [../magi/common.nix];

  # installer greps the host dir for this to put the sops key under /persist
  impermanence.enable = true;

  networking.hostName = "casper";
  networking.hostId = "47725faa";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./casper.pub];
}
