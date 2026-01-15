{
  pkgs,
  lib,
  config,
  ...
}: {
  options.vm.enable = lib.mkEnableOption "virtualization support (libvirt, virt-manager, Docker)";

  config = lib.mkIf config.vm.enable {
    programs.dconf.enable = true;
    users.users.xhos.extraGroups = ["libvirtd"];

    environment.systemPackages = with pkgs; [
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      # win-virtio
      # win-spice
      adwaita-icon-theme
    ];

    services.qemuGuest.enable = true;
    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = ["xhos"];
    virtualisation = {
      docker.enable = true;
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          # ovmf.enable = true;
          # ovmf.packages = [pkgs.OVMFFull.fd];
        };
      };
      spiceUSBRedirection.enable = true;

      vmVariant = {
        virtualisation = {
          memorySize = 8192;
          cores = 4;
          graphics = true;
          resolution = {
            x = 1920;
            y = 1080;
          };
        };
      };
    };

    services.spice-vdagentd.enable = true;
  };
}
