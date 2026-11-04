{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  profile = "full";

  virtualisation.docker.enable = true;

  wsl.enable = true;
  wsl.defaultUser = "xhos";

  # scanning the windows PATH over 9p makes completion and command-not-found
  # crawl; the few windows binaries we want get shims in modules/home/opt/wsl.nix
  wsl.interop.includePath = false;
  wsl.wslConf.interop.appendWindowsPath = false;

  # tailscale owns resolv.conf. wsl can rewrite it mid-session, which
  # silently sends *.ts.xhos.dev to public dns and lands on proxy-1 instead
  wsl.wslConf.network.generateResolvConf = false;

  # WSL's init mounts its own tmpfs (holding the WSLg wayland-0 symlinks) over
  # /run/user/<uid> right before it opens the login session. With linger, user@<uid>
  # has started seconds earlier, so its bus and sockets end up in the shadowed
  # mount and switch-to-configuration fails with "Failed to open dbus connection".
  # Hold user@ until WSL's mount is in place so everything lives in the visible one.
  systemd.services."user@".serviceConfig.ExecStartPre = let
    waitForWslMount = pkgs.writeShellScript "wait-for-wsl-runtime-dir" ''
      dir=/run/user/$1
      [ -d /mnt/wslg ] || exit 0
      # WSL waits up to 10s for systemd to finish booting before it mounts,
      # so the timeout has to be longer than that.
      for _ in $(${pkgs.coreutils}/bin/seq 1 75); do
        n=$(${pkgs.gawk}/bin/awk -v d="$dir" '$5 == d' /proc/self/mountinfo | ${pkgs.coreutils}/bin/wc -l)
        [ "$n" -ge 2 ] && exit 0
        ${pkgs.coreutils}/bin/sleep 0.2
      done
      echo "WSL runtime dir mount did not appear on $dir, starting anyway" >&2
    '';
  in ["${waitForWslMount} %i"];

  # Fallback for when the wait above loses the race anyway: restart user@ if its
  # bus socket is missing so the rebuild can still reload user units.
  system.activationScripts.wslUserBus.text = let
    user = config.wsl.defaultUser;
    systemctl = "${config.systemd.package}/bin/systemctl";
  in ''
    if [ -d /run/systemd/system ]; then
      uid=$(id -u ${user} 2>/dev/null || true)
      if [ -n "$uid" ] && ${systemctl} is-active --quiet "user@$uid.service" \
         && [ ! -S "/run/user/$uid/bus" ]; then
        echo "user bus for ${user} hidden by WSLg mount, restarting user@$uid.service"
        ${systemctl} restart "user@$uid.service" || true
      fi
    fi
  '';

  # obsidian notes, synced with enrai. the vault lives on the
  # windows drive because obsidian can't watch \\wsl.localhost paths (EISDIR),
  # and outside Documents since that's redirected to the work onedrive
  syncthing = {
    enable = true;
    notesPath = "/mnt/c/Users/KudriaMa/notes";
  };

  networking.hostName = "aevon";
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
