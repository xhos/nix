{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
  ];

  nixpkgs.overlays = [
    (final: prev: {
      lkl = prev.lkl.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace tools/lkl/cptofs.c \
              --replace-fail 'lkl_start_kernel("mem=100M")' 'lkl_start_kernel("mem=6144M")'
          '';
      });
    })
  ];

  system.build.OCIImage = lib.mkForce (
    import "${inputs.nixpkgs}/nixos/lib/make-disk-image.nix" {
      inherit config lib pkgs;
      inherit (config.virtualisation) diskSize;
      name = "oci-image";
      baseName = config.image.baseName;
      configFile = builtins.path {
        name = "oci-config-user.nix";
        path = "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-config-user.nix";
      };
      format = "qcow2";
      partitionTableType =
        if config.oci.efi
        then "efi"
        else "legacy";
      memSize = 8192;
    }
  );

  networking.hostName = "a1-flex";
  nixpkgs.hostPlatform = "aarch64-linux";

  virtualisation.diskSize = 8192;

  # NO lib.mkForce override needed anymore

  users.users.root.openssh.authorizedKeys.keyFiles = [../arashi/arashi.pub];
  services.openssh.settings.PermitRootLogin = "yes";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  system.stateVersion = "25.11";
}
