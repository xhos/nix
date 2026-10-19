{
  inputs,
  lib,
  config,
  ...
}: let
  sopsFolder = toString inputs.nix-secrets;
in {
  imports = [inputs.sops-nix.nixosModules.sops];
  sops = {
    defaultSopsFile = "${sopsFolder}/secrets.yaml";
    validateSopsFiles = false;
    age = {
      # follows hostKeys, which impermanence points at /persist/etc/ssh
      sshKeyPaths = map (k: k.path) (lib.filter (k: k.type == "ed25519") config.services.openssh.hostKeys);
      keyFile = "/var/lib/sops-nix/key.txt"; # this will use an age key that is expected to be already in the filesystem
      generateKey = true; # genrete new key if above does not exist
    };
  };
}
