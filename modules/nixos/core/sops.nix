{inputs, ...}: let
  sopsFolder = toString inputs.nix-secrets;
in {
  imports = [inputs.sops-nix.nixosModules.sops];
  sops = {
    defaultSopsFile = "${sopsFolder}/secrets.yaml";
    validateSopsFiles = false;
    age = {
      sshKeyPaths = [
        "/persist/etc/ssh/ssh_host_ed25519_key" # when initrd need this
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "/var/lib/sops-nix/key.txt"; # this will use an age key that is expected to be already in the filesystem
      generateKey = true; # genrete new key if above does not exist
    };
  };
}
