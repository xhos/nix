# ❄️ nix

<details>
<summary>old screenshots</summary>

## old setup using [aard](https://github.com/xhos/aard)

<p float="left">
  <img src="./.github/ss1.png" width="400" />
  <img src="./.github/ss2.png" width="400" /> 
  <img src="./.github/ss3.png" width="400" />
  <img src="./.github/ss4.png" width="400" />
</p>

</details>

all wallpapers can can be found [here](https://pics.xhos.dev/folder/cmgs64vh4000amzfs6t7oqy3f)

## main features

- modular setup, everything is toggleable and switchable
- easy full system theming with stylix, based on the wallpaper or a base16 scheme
- secret management with sops-nix
- touch support with hyprgrass
- integrated onedrive & protondrive mounts
- preconfigured web apps
- fully-themed login screens with sddm and grub

## homelab

[enrai](../hosts/enrai) is my headless optiplex 5050 running a bunch of cool things, ~99% declarative. zsh, impermanence, secrets, all that good stuff:

- fully declarative *arr stack thanks to [upidapi's](https://github.com/upidapi) [declarr](https://github.com/upidapi/declarr). (tho i use [my own fork](https://github.com/xhos/declarr) of it for some extra features)
- networking: caddy reverse proxy with cloudflare acme + nat port forwarding over wirguard to the vps running my [nix-wg-proxy](https://github.com/xhos/nix-wg-proxy)
- home assistant: yandex station max controlling wled and [wled-album-sync](https://github.com/xhos/wled-album-sync)
- proxmox-nix running 2 vms, one for game servers, other for amnezia vpn (the only not fully declarative part)
- zipline, wakapi, synthing, glance and more

## repo structure

- **[flake.nix](./flake.nix):** main entrypoint, defines system and home configurations
- **[lib/](./lib):** custom Nix library functions and builders (e.g., `import-tree`)
- **[modules/](./modules):**
  - **[home/](./modules/home):** home-manager modules
    - **[core/](./modules/home/core):** essential user configurations and host-specific entrypoints (prefixed with `_`)
    - **[opt/](./modules/home/opt):** optional and toggleable modules (apps, cli tools, bar, wms, etc)
  - **[nixos/](./modules/nixos):** system-level modules
    - **[core/](./modules/nixos/core):** base system configs, and per-host definitions (prefixed with `_`)
    - **[opt/](./modules/nixos/opt):** optional and toggleable modules (impermanence, nvidia config, etc)
- **[pkgs/](./pkgs):** custom packages and derivations

### about `import-tree` and `mk-nixos-system`

usually, in nix code you have to import each file, or folder if using `default.nix` one by one. But in my config I am using import-tree pointed at the `default.nix` files at the top of `nixos/` and `home/` that look like `{inputs, ...}: inputs.import-tree [./core ./opt]`. This allows every single file in those 2 folder to be imported automaticly, without adding it to an import list in any other file. No other default.nix files are needed. 

Since hosts need to have their own separate thin modules, that should not be imported by others, import-tree ignores any folder that starts with `_`. This allows my home-manager and nixos entry points to live under `modules/home/core/_vyverne/home.nix`.

`mk-nixos-system` is another custom function. It's a helper that returns `lib.nixosSystem` and takes in the hostname and some other args. Based on that host name, it finds the right entry points for nixos and home-manager.


## info

| component          | details                                                 |
| ------------------ | ------------------------------------------------------- |
| de/wm              | [hyprland](https://hypr.land/)                          |
| greeter            | [yawn](https://github.com/xhos/yawn) (i made this!)     |
| terminal           | [foot](https://codeberg.org/dnkl/foot)                  |
| shell              | [zsh](https://www.zsh.org/)                             |
| bar                | [waybar](https://github.com/Alexays/Waybar)             |
| browser            | [zen](https://zen-browser.app)                          |
| runner             | [rofi](https://github.com/davatorium/rofi)              |
| prompt             | [starship](https://starship.rs/)                        |
| file manager       | [nautilus](https://apps.gnome.org/Nautilus/)            |
| notification       | [mako](https://github.com/emersion/mako)                |
| clipboard manager  | [clipse](https://github.com/savedra1/clipse)            |
| fetch              | [fastfetch](https://github.com/fastfetch-cli/fastfetch) |

## hyprlock

| name | preview | sources |
| :--- | :--- | :--- |
| **Main (Animated)** | <img src=".github/hyprlock.gif" alt="main Hyprlock Style" width="400" /> | [config](https://github.com/xhos/nix/tree/9692b91df9fa7896a59af807010780d1c9bffad7/modules/home/opt/hypr/hyprlock/hyprlock.conf) <br> [assets](https://github.com/xhos/nix/tree/9692b91df9fa7896a59af807010780d1c9bffad7/modules/home/opt/hypr/hyprlock/assets/) <br> [scripts](https://github.com/xhos/nix/tree/9692b91df9fa7896a59af807010780d1c9bffad7/modules/home/opt/hypr/hyprlock/scripts/) <br> [fonts](../modules/home/core/fonts/font-files/) |
| **Alternative (Static)** | <img src=".github/hyprlock-alt.png" alt="alternative Hyprlock Style" width="400" /> | [config](https://github.com/xhos/nix/tree/9692b91df9fa7896a59af807010780d1c9bffad7/modules/home/opt/hypr/hyprlock/hyprlock-alt.conf) <br> [assets](https://github.com/xhos/nix/tree/9692b91df9fa7896a59af807010780d1c9bffad7/modules/home/opt/hypr/hyprlock/assets/) <br> [scripts](https://github.com/xhos/nix/tree/9692b91df9fa7896a59af807010780d1c9bffad7/modules/home/opt/hypr/hyprlock/scripts/) <br> [fonts](../modules/home/core/fonts/font-files/) |

fonts used are:

- Maratype (credit to @notevencontestplayer on discord)
- KH Interference
- Synchro
- Nimbus Sans L Thin
- Nimbus Sans Black

## themed apps

> [!note]
> most of these automatically follow the stylix color scheme

- discord:  [system24](https://github.com/refact0r/system24)
- firefox:  [scifox](https://github.com/scientiac/scifox)
- obsidian: [anuppuccin](https://github.com/AnubisNekhet/AnuPpuccin)
- spotify:  [text](https://github.com/spicetify/spicetify-themes/tree/master/text)
- and more that i'm forgetting...

## installing

mostly notes for myself for re-deploying/re-installing

### bare metal

1. Build the ISO with [the GitHub Action](https://github.com/xhos/nix/actions/workflows/build-iso.yml)
2. Burn it onto a USB stick, with [caligula](https://github.com/ifd3f/caligula)
3. Install 

### nixos-infect (for low power VPS)

on target host (assumed ubuntu 22.04 on Oracle Cloud, meaning "ubuntu" as the default user)

```sh
sudo apt update && sudo apt upgrade -y
```

make root ssh work

```sh
sudo mkdir -p /root/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/
sudo chown root:root /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys
```

```sh
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
```

```sh
sudo systemctl restart ssh
```

```sh
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-25.11 doNetConf=y bash -x
```

### nixos-anywhere (prefered for decent VPS)

## acknowledgments

- [@joshuagrisham](https://github.com/joshuagrisham) for his work on [the galaxy book driver](https://github.com/joshuagrisham/samsung-galaxybook-extras)
- [@itzderock](https://github.com/ItzDerock) for sharing his [nix derivation](https://github.com/joshuagrisham/samsung-galaxybook-extras/issues/14#issue-2328871732) for that driver (now irrelevant since it was merged upstream)
- [@elyth](https://github.com/elythh), my config started as a fork of his [flake](https://github.com/elythh/flake)
- [hyprstellar](https://github.com/xeji01/hyprstellar/tree/main) for icons and general style inspiration
