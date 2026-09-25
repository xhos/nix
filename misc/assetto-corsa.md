# Assetto Corsa on vyverne

## Read this first — status on 2026-09-21

The user confirmed Content Manager opens, detects their Steam account and
`D:\` game folder, and launches a stock car/track that they can drive.
Treat this as the working baseline. Do not recreate the prefix to debug a
new mod without preserving the user's current settings first.

The user wants to stay entirely on NixOS and follow ordinary Windows modding
guides with minimal translation. They plan to develop a modpack loader later;
that tool is not part of this setup. They do **not** have space for another
30+ GB game copy. No full-game backup is required or automated; the original
`backup` command was removed during cleanup.

CSP, Pure/Sol, online sessions, wheel force feedback, and external Windows
installers have not been verified by us in this environment. The installer
command supports EXE/MSI/BAT/CMD, but support in the wrapper is not evidence
that every particular installer works. The user was advised to install CM's
7-Zip plugin; its installation has not been independently confirmed.

## Components and ownership

This setup uses native Steam with GE-Proton9-20, Content Manager
0.8.2782.39874, and an optional CSP 0.2.11 baseline. The downloads are
hash-pinned in `pkgs/assetto-corsa-env.nix`. The game remains in its existing
Steam library; the stock launcher is not replaced.

| Repository file | Responsibility |
| --- | --- |
| `pkgs/proton-ge-9-20.nix` | Existing pinned Proton package; also exposed to Steam by the gaming module |
| `pkgs/assetto-corsa-env.nix` | Pinned CM/CSP/font downloads, dependencies, and shell wrapper |
| `pkgs/assetto-corsa/env.sh` | Setup, launch, installer, diagnostic and CSP commands |
| `pkgs/assetto-corsa/Values.data` | Initial CM settings, copied only when absent |
| `systems/vyverne/home.nix` | Package, CM shortcut, installer Open With entry and `acmanager://` association |

Packages are discovered by `lib/pkgs-overlay.nix`. The shell/data files live
in a subdirectory so the overlay does not mistake them for package definitions.
Desktop integration is enabled only on vyverne. No changes to the unrelated
`modules/home/core/pkgs.nix` work are part of this feature.

Nix pins the initial CM executable and the Proton package, not mutable game
files or CM state. A rebuild does not reset settings or replace an existing
CM executable. Steam Linux Runtime and graphics drivers are not frozen by
this package. CM's auto-update setting is initially off, but the user can
change it later.

## Daily use

Open **Assetto Corsa Content Manager** from the application menu.
Alternatively, run `assetto-corsa-env cm`. Native Steam must be signed in;
the launcher starts it if necessary. In CM, use the **AppID** game starter.

Windows instructions translate to these paths:

| Windows path | Linux path |
| --- | --- |
| `D:\` (Assetto Corsa root) | `/games/SteamLibrary/steamapps/common/assettocorsa` |
| `C:\` | `/games/assetto-corsa/compatdata/pfx/drive_c` |
| `Documents\Assetto Corsa` | `/games/assetto-corsa/compatdata/pfx/drive_c/users/steamuser/Documents/Assetto Corsa` |
| `%LOCALAPPDATA%\AcTools Content Manager` | `/games/assetto-corsa/compatdata/pfx/drive_c/users/steamuser/AppData/Local/AcTools Content Manager` |

For a mod's Windows installer, select **Open with → Run in Assetto Corsa**,
or run:

```sh
assetto-corsa-env run /path/to/installer.exe
assetto-corsa-env run /path/to/installer.msi
assetto-corsa-env run /path/to/install.bat
assetto-corsa-env explorer
```

These commands use the same prefix and Proton version as CM. When a guide
says to copy files into the game directory, use `D:\` or the Linux game
directory above. For archives, use CM's **Install from a file** menu if
dragging from a Linux file manager does not work.

The Steam Play button still starts the original launcher using Steam's own
compatibility selection. Use the CM shortcut for this managed environment.
Do not run system Wine directly against this prefix or change its Proton
version in place.

## Setup and maintenance

The package and desktop integration are declared in `systems/vyverne/home.nix`.
Build the launcher alone with:

```sh
nix build .#nixosConfigurations.vyverne.pkgs.assetto-corsa-env
./result/bin/assetto-corsa-env setup
```

`setup` can resume an interrupted installation and leaves the original
Steam prefix at `steamapps/compatdata/244210` untouched. The dedicated prefix,
download cache and temporary files live under `/games/assetto-corsa` on the
persistent games disk. CM starts with software rendering for its interface;
this does not disable GPU rendering in the game.

Initial CM settings disable automatic CM upgrades and Discord integration.
Update deliberately after recording the working versions. Pinning Wine
does not guarantee compatibility with every Windows mod, new CSP version,
driver, or external installer.

```sh
assetto-corsa-env status
assetto-corsa-env winetricks list-installed
assetto-corsa-env install-csp  # only accepts a game with no existing CSP
```

Setup holds an exclusive maintenance lock and verifies Protonfixes installed
`dotnet452`, `d3dx11_43`, `d3dcompiler_47`, and `win10`; then installs corefonts.
`setup-complete` is written last. Re-running setup after completion is a
no-op, not an upgrade or reset command. The lock coordinates this wrapper's
processes, not programs launched independently; close all users of the prefix
before maintenance. Never delete the completion marker just to force changes.

`AC_GAME_DIR`, `AC_STATE_DIR`, and `STEAM_DIR` override the default paths.
Use absolute paths. All related launches must use the same state directory.
If the game moves, update the existing `pfx/dosdevices/d:` mapping as well;
setup intentionally refuses to overwrite a different mapping.

### CM interface font (manual prefix customization, 2026-09-21)

Historical workaround (disabled 2026-09-23): Hyprland on vyverne hid the untitled floating XWayland window with
class `steam_app_244210` via `assetto-corsa-wine-shell`, declared alongside
the CM desktop entries in `systems/vyverne/home.nix` and automatically
loaded as the separate Hyprland Lua module `assetto-corsa.lua`.
Observed as 107×13 pixels, owned by Wine `explorer.exe /desktop`, not the
game. Match includes empty current title and floating state so the titled
`Assetto Corsa` window remains visible. Rule disables opacity, decorations,
blur, shadows and focus, without killing Wine Explorer. Applied live and
accepted without config errors on 2026-09-22; repo rule requires normal
configuration activation for persistence across reloads/reboots.
Disabled live and removed from the repo Lua module after the user reported
broken CM dropdowns: their windows may share the same untitled floating
`steam_app_244210` properties. User confirmed disabling it restored dropdowns.
Do not restore the broad match.
Until the next rebuild, reloading the old installed configuration can restore
the rule.

Replacement (2026-09-23): the same module now checks windows on open and
scans existing windows on load. It requires the AC class, empty title,
floating state, dimensions at most 200×32, `/proc/PID/comm` exactly
`explorer.exe`, and command line ending in `/desktop`. Only then does it
apply the static `ac-explorer-desktop` tag. The hide rule matches that tag,
not the shared class/title; CM processes cannot qualify. Missing process
data leaves a window untouched. Verified live: Explorer window tagged and
invisible, game untagged and visible, no Hyprland config errors. User visual
confirmation of dropdowns with the new rule remains pending. Rebuild to
replace the old installed module; live changes alone do not survive reload.

The prefix had `HKCU\Software\Wine\Fonts\Replacements` mapping `Segoe UI`
to `Times New Roman`, and no Segoe UI font files. With CM/Wine stopped,
installed the user's four TTFs from
`~/Downloads/segoe-ui-4-cufonfonts` into `pfx/drive_c/windows/Fonts` as
`segoeui.ttf`, `segoeuib.ttf`, `segoeuii.ttf`, and `segoeuiz.ttf`.
Registered regular/bold/italic/bold-italic under
`HKLM\Software\Microsoft\Windows NT\CurrentVersion\Fonts` and removed only
the Segoe UI replacement. Registry backups are `pfx/user.reg.before-segoe`
and `pfx/system.reg.before-segoe`. No system-wide font change or CM theme
override was made. Fonts remain in the persistent prefix, but are not bundled
in the Nix package; a fresh prefix needs them installed separately.
Visual confirmation in CM is still pending.

### Storage and recovery with limited disk space

#### Low-VRAM diagnostic preset (2026-09-24)

Applied with AC and CM stopped, in the dedicated prefix's Documents/Assetto
Corsa/cfg/extension: `general.ini` now has `[OPTIMIZATIONS_MEMORY]`
`LIMIT_TEXTURES_MAIN_CAR=1024`, `LIMIT_TEXTURES_TRACK=1024`, existing
`LIMIT_TEXTURES_OTHER_CARS=512`, and `FIX_MISSING_BC_MIPS=1`.
`graphics_adjustments.ini` has `[LODS]`
`SKIP_LOADING_FIRST_LOD_FOR_OTHER_CARS=1`, preserving the user's 0.5 car
LOD-distance multiplier. Created `extra_fx.ini` with `[BASIC] ENABLED=0`
(already the installed CSP default, now explicit). Pure and server files
were not changed. These are runtime user settings, not enforced by Nix.

Original general/graphics files are backed up beside them with suffix
`.before-low-vram-20260924`; rollback restores those two and removes the
new `extra_fx.ini`. Performance/VRAM savings remain unverified until the
next server session. Earlier 512-only test did not appreciably lower VRAM.

#### Pure reinstall (2026-09-22)

User's controlled test: stock car ~13 FPS with Pure, ~162 FPS with CSP
disabled, ~200 FPS with CSP enabled but Weather FX disabled; user also
reported default weather did not exhibit the Pure slowdown. This isolates
the issue to the Pure path, not the NVIDIA GPU (live `acs.exe` and CSP's
hardware report both confirmed RTX 3060). Reinstall is a diagnostic step,
not a verified performance fix.

Installed by native file copy from
`~/Downloads/Pure 3.50 Highres/Pure 3.50`, followed by
`~/Downloads/Pure 3.50 Hotfix5 (Pure 3.55).zip`. Validated all 791 base files
against the base ZIP before installation, tested the hotfix archive, and
verified all 794 resulting files by size and CRC. The source package has a
third-party Telegram README; archive checks establish consistency, not
publisher authenticity. No bundled scripts were executed.

Existing Pure-specific directories (including settings/presets) and exact
overlapping files in shared directories were moved, not deleted, into
`/games/assetto-corsa/pure-rollback-20260922-215521/game`.
The adjacent `manifest.json` records affected paths and new installed files.
Cars, tracks, CSP files and current CM/Weather FX selection were left alone.
Rollback data occupies the original space; the new copy adds about 3.6 GB.
Do not blindly merge the rollback over the new installation: remove/move
only the installed manifest paths first, then restore saved originals.
Test FPS before deleting rollback data or restoring old Pure settings.

`/games` is persistent ext4. `/nix` and `~/nix` are persistent ZFS storage.
Vyverne's root and `/tmp` are RAM-backed and reset at reboot, and the default
`~/.cache/winetricks` is not persisted. The wrapper sets `WINETRICKS_CACHE`,
`XDG_CACHE_HOME`, and `TMPDIR` under `/games/assetto-corsa` so installer work
survives reboots. Nix build sandboxes and Steam's runtime can still use their
own temporary directories; these settings do not globally relocate `/tmp`.

For future diagnostics, keep downloads/build outputs outside the repo and on
disk-backed persistent storage. Do not use a `path:` flake over this whole
working directory: it can copy ignored disk images and scratch prefixes into
the store. Use the regular Git flake and make new source files visible to Git.

There is no automatic backup. If needed, save only CM settings and
`Documents/Assetto Corsa` first. A complete prefix backup also preserves .NET,
registry and installed Windows dependencies; it was about 1.7 GB during
cleanup, and can grow. Check space before copying even that. None of these
small backups restore game files or mods.

For broken stock game files, Steam verification can restore stock files, but
does not reliably remove extra files added by mods. Record files installed
by each mod, and back up individual overwritten files when practical.
A NixOS rollback alone does not roll back the prefix or game content.

To restore a saved prefix, close CM/game/installers, move the current prefix
aside, then restore the saved `compatdata` with symlinks preserved. Retain the
matching CM executable and Proton version. Never merge old prefix files into
a running or differently-versioned prefix. The original Steam prefix at
`/games/SteamLibrary/steamapps/compatdata/244210` remains separate and is not a
backup of the working CM environment.

## Runtime details worth preserving

- Launch chain: `steam-run` → Steam Linux Runtime `sniper` → pinned Proton
  → CM or installer. Direct use of the generic NixOS `steam-run` environment
  produced font-library warnings during testing; the Steam runtime was used
  for the working launch path.
- `STEAM_COMPAT_MOUNTS` must expose the state directory as well as the game.
  Without it, the runtime could see the prefix but not its sibling CM EXE,
  and Proton failed to create the process with error 2. External installer
  directories are added to the mount list too.
- CM uses software rendering for its WPF interface. The game still uses the
  GPU. `dwrite=n,b` enables CSP's DLL when installed; `winemenubuilder.exe=d`
  suppresses Wine-generated desktop associations.
- CM reads native Steam identity through a symlink to `config/loginusers.vdf`
  under the prefix's `Program Files (x86)/Steam/config`. Do not copy or print
  Steam credentials while debugging this.
- CM defaults disable its Discord integration, Windows-side Steam startup,
  and automatic CM upgrades. Native Steam is started asynchronously by the
  wrapper; it must finish starting/signing in before a race can launch.
- `Values.data` is CM's version-2 storage format: tab-separated keys/values,
  with escaped backslashes. The launch flag keeps later saves uncompressed.
  It is a seed, not a declaratively enforced file; preserve user changes.
- Windows Start Menu shortcuts are unnecessary; use the NixOS shortcut.
  Optional CefSharp and other CM plugins were intentionally not preinstalled.
- `install-csp` is an explicit, optional first-install operation that refuses
  an existing `dwrite.dll` or `extension` directory. It does not update CSP or
  recover a partially extracted installation automatically.

## Diagnostics

CM logs are in its `Logs` directory under `%LOCALAPPDATA%`. AC and CSP logs
are under `Documents\Assetto Corsa\logs`. For a Proton trace:

```sh
PROTON_LOG=1 PROTON_LOG_DIR=/games/assetto-corsa/logs assetto-corsa-env cm
```

After a desktop freeze, inspect the previous boot:

```sh
journalctl -b -1 -k
```

The freeze during initial testing on 2026-09-20 recorded NVIDIA Xid 8 and
Hyprland/display failures. No OOM kill or disk-full error was found. The
trigger was not established.

The temporary `/tmp` downloads were lost in that reboot; the test prefix in
`~/nix/temp` survived and was copied to `/games/assetto-corsa/compatdata`.
The scratch copies and temporary build links in the repo are not required
by the installed environment.

ShellCheck runs as part of `writeShellApplication` builds. A previous build
failure was SC2155 from `export VAR="$(command)"`; keep assignment and export
separate where command substitution is used. Check the actual package build,
not just `bash -n`, before handing off changes:

```sh
nix build .#nixosConfigurations.vyverne.pkgs.assetto-corsa-env --no-link
git diff --check
```

Builds validate packaging, not gameplay. The stock-driving confirmation is
from the user, not an automated test. Do not describe CSP or modpacks as
tested until they have actually been exercised.

## Upstream references

- [Content Manager](https://acstuff.club/app/)
- [Pinned CM release](https://github.com/gro-ove/actools/releases/tag/v0.8.2782.39874)
- [Community Linux setup used as a reference](https://github.com/sihawido/assettocorsa-linux-setup)
- [Protontricks](https://github.com/Matoking/protontricks)
- [NVIDIA Xid documentation](https://docs.nvidia.com/deploy/xid-errors/analyzing-xid-catalog.html)

The community installer was not run wholesale: it does not support NixOS's
package workflow and replaces the stock launcher. Our wrapper keeps CM
separate and reuses the existing Steam game download.
