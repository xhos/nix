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

  # cptofs hardcodes mem=100M in C source, not enough for a full NixOS closure
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

  # oci-image.nix never passes memSize to make-disk-image.nix (nixpkgs#479591)
  # also strip kvm requirement as OCI ARM VMs don't expose /dev/kvm
  system.build.OCIImage = lib.mkForce (
    let
      base = import "${inputs.nixpkgs}/nixos/lib/make-disk-image.nix" {
        inherit config lib pkgs;
        inherit (config.virtualisation) diskSize;
        name = "oci-image";
        baseName = config.image.baseName;
        format = "qcow2";
        partitionTableType =
          if config.oci.efi
          then "efi"
          else "legacy";
        memSize = 8192;
        configFile = builtins.path {
          name = "oci-config-user.nix";
          path = "${inputs.nixpkgs}/nixos/modules/virtualisation/oci-config-user.nix";
        };
      };
    in
      lib.overrideDerivation base (old: {
        requiredSystemFeatures = lib.filter (f: f != "kvm") (old.requiredSystemFeatures or []);
        nativeBuildInputs =
          map
          (p:
            if (p.pname or "") == "qemu-kvm"
            then pkgs.qemu
            else p)
          (old.nativeBuildInputs or []);
      })
  );

  networking.hostName = "a1-flex";
  nixpkgs.hostPlatform = "aarch64-linux";

  virtualisation.diskSize = 8192;

  users.users.root.openssh.authorizedKeys.keyFiles = [../arashi/arashi.pub];
  services.openssh.settings.PermitRootLogin = "yes";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  system.stateVersion = "25.11";
}
