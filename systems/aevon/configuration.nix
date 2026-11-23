{
  hosts.aevon = {
    nixos = {
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

      networking.hostName = "aevon";
      nixpkgs.hostPlatform = "x86_64-linux";

      system.stateVersion = "25.05";
    };

    home = {
      config,
      pkgs,
      ...
    }: {
      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";

      headless = true;

      modules.secrets.enable = true;

      modules.wsl = {
        windowsHome = "/mnt/c/Users/KudriaMa";
        memory = "10GB"; # host has 16GB
        terminalProfileGuid = "{41ae03f2-5542-51cf-a1c0-3a444db570ec}";
      };

      # eiad's own `build` devshell script compiles into .build/
      home.sessionPath = ["${config.home.homeDirectory}/work/eiad/.build"];

      shell = "zsh";
      prompt = "starship";
    };
  };
}
