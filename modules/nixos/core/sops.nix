{inputs, ...}: let
  secretspath = builtins.toString inputs.nix-secrets;
in {
  imports = [inputs.sops-nix.nixosModules.sops];
  sops = {
    defaultSopsFile = "${secretspath}/secrets.yaml";
    validateSopsFiles = false;
    age = {
      # import host ssh key as age key
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      # this will use an age key that is expected to be already in the filesystem
      keyFile = "/var/lib/sops-nix/key.txt";
      # genrete new key if above does not exist
      generateKey = true;
    };
  };
}
