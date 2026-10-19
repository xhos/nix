{
  imports = [../magi/common.nix];

  # installer greps the host dir for this to put the sops key under /persist
  impermanence.enable = true;

  networking.hostName = "balthasar";
  networking.hostId = "a064d856";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./balthasar.pub];
}
