# Assetto Corsa server (AssettoServer on enrai)

Handoff notes, last updated 2026-09-23. Client-side setup on vyverne is in
`misc/assetto-corsa.md`; this file is about the server.

## Status

- `assetto-server-srp.service` on enrai is live and reachable from the
  internet via proxy-1. Deployed config: commit `c04cd14` (trimmed car list,
  53 entry-list slots).
- SRP 0.9.4 PTB1 `main_layout`, AI traffic with the plot3sale & Lay Jeno v6
  spline, minimum CSP 4157, password protected, not listed in the public lobby.
- Verified working: joins through proxy-1 (xhos, Dyse), AI traffic, CM
  "Install missing content" (Dyse downloaded everything this way), download
  password protection (401 without password).

## How friends join

- Link: `https://acstuff.club/s/q:race/online/join?ip=40.233.109.227&httpPort=8081`
  (`acmanager://race/online/join?ip=40.233.109.227&httpPort=8081` also works).
  Ignore the invite link in the server log: it has enrai's home IP
  (167.254.134.71), which forwards nothing.
- CM manual add: Online → Favourites → `+` → `40.233.109.227:8081`.
- First time: enter the password, click **Install missing content**, wait, then
  click **Install all** in CM's downloads panel (arrow icon, top right). CM
  always waits for that confirmation; no setting skips it. If they skip it,
  CM re-downloads on the next join.
- Friends need CSP ≥ 4157 (build number) themselves; CM can install CSP.

## Files

| File | What |
| --- | --- |
| `pkgs/assetto-server.nix` | AssettoServer 0.0.55-pre38, linux-x64 release tarball, autoPatchelf'd (only ELF interp/rpath; `dontStrip`/`dontPatchELF` so the .NET single-file bundle survives) |
| `modules/nixos/opt/homelab/services/assetto-server.nix` | Reusable module, `homelab.assetto-server.instances.<name>` |
| `systems/enrai/configuration.nix` | The `srp` instance: cars, spline, ports, overrides |

Secrets in nix-secrets `secrets.yaml` (values must be YAML **strings** — an
all-digits password without quotes becomes an int and sops-nix refuses it):

```yaml
assetto-server:
    srp:
        password: "..."        # join + CM download password
        admin-password: "..."  # /admin in chat
```

## How the module works

Each start, `assetto-server-<name>-prepare` (ExecStartPre) in
`/var/lib/assetto-server/<name>` (persisted):

1. Writes `cfg/server_cfg.ini`, `entry_list.ini`, `extra_cfg.yml`,
   `cm_wrapper_params.json`, `cm_content/content.json` from Nix; substitutes
   passwords from sops with `replace-secret`. Other files in `cfg/` (server
   caches like `data_track_params.ini`) are left alone.
2. Builds a symlink farm `content/` pointing into `contentDir`, only for cars in
   the entry list. The track is mirrored down to the layout's `ai/` folder so
   `fast_lane.aip` is visible to the server only — `contentDir` stays
   byte-identical to what clients download.
3. Zips each car and the track into `downloads/` for CM direct download; only
   re-zips when a source file is newer than the zip. First start after adding a
   lot of cars takes minutes (deploy sits on "starting assetto-server-srp").

Missing secret / car / track / spline → prepare exits 78, which is in
`RestartPreventExitStatus`, so the unit stops with a clear log line instead of
looping.

Content lives outside the store, owned by `homelab.assetto-server.contentOwner`
(xhos on enrai), dirs created by tmpfiles:

```
/storage/assetto/content/cars/<car>          # full car folders, as clients have them
/storage/assetto/content/tracks/shutoko_revival_project_094_ptb1
/storage/assetto/splines/srp-094ptb1-plot3sale-v6.aip
```

`public = true` adds `homelab.tcpForwards` for 9600/tcp, 9600/udp, 8081/tcp,
which proxy-1 turns into DNAT rules to enrai's tailnet IP. OCI's security
list already allows all TCP/UDP.

## Common tasks

### Add / remove a car

1. Copy the car folder to enrai (from a Linux box with the game; from Windows use
   WinSCP or `scp -r` to `enrai:/storage/assetto/content/cars/`):
   ```sh
   rsync -a <game>/content/cars/<car_id> enrai:/storage/assetto/content/cars/
   ```
   Use the exact folder everyone else will have — the server checksums
   `data.acd` against clients.
2. Add `"<car_id>"` to `playerCars` (1 slot each) or `trafficCars` in
   `systems/enrai/configuration.nix`.
3. Commit, pull on enrai, `nh os switch .` (restart kicks everyone).

A car without `data.acd` (unpacked `data/` folder) makes the server refuse to
start unless `extraCfg.IgnoreConfigurationErrors.MissingCarChecksums = true`
(currently on, for `ks_nissan_gtr_boss_MAIN`). That only skips the check for
cars lacking `data.acd`; others are still verified. Packing the data in CM
(car page → Pack data) is the cleaner fix.

Removed cars can stay in `/storage` and `downloads/` — harmless.

Keep the list short: every client loads **every entry-list car model** at join
(see the VRAM section).

### Current cars

Player (1 slot each): bati_fd3s_rx7, art_mazda_fd3s_rx7_black_eagle,
sl_toyota_supra_mkiv_ridox, ddm_nissan_silvia_s15, wm_nissan_s15,
wm_nissan_fairlady_z_s30, art_nissan_gtr_bcnr33_600r, ks_nissan_gtr_boss_MAIN,
aegis_mitsubishi_lancer_evolution_v_gsr (Evo V "Aeroblitz", not from the SRP
pack), slang_ferrari_f40, ddm_subaru_22b, j8_ae86_tuned_coupe, honda_acty_ha3.

Traffic: 10 models × 4 slots from the SRP car pack 3.6 (`traffic_*`).

### Admin / weather (in-game chat)

`/admin <admin-password>` once per session (reply: "You are now Admin").

```
/setcspweather Rain 60        # type, transition seconds; /cspweather lists types
/setcspweather Clear 0
/settime 23:30                # H:mm
/setrain 0 0.6 0.3            # intensity wetness water, 0..1
/kick, /ban, /say, /whois, /pit, /setgrip, /set
```

All reset on restart. `/setweather <id>` only switches `WEATHER_n` presets and
we only define `WEATHER_0`. No web admin panel exists. RCON is available via
`extraCfg.RconPort` if wanted (not enabled; would be tailnet-only).

### Manual download links (if a friend's CM install button is broken)

```sh
read -rs "pw?server password: "; echo
h=$(printf 'tanidolizedhoatzin%s' "$pw" | sha1sum | cut -d' ' -f1)
u=http://40.233.109.227:8081/content
echo "$u/track?password=$h"
for c in $(curl -s $u/../api/details | python3 -c 'import json,sys; print(" ".join(json.load(sys.stdin)["content"]["cars"]))'); do echo "$u/car/$c?password=$h"; done
```

Friend opens each, drags the zips onto CM, **Install all**. Links contain the
password hash — share privately.

## Checking on it

```sh
ssh enrai
systemctl status assetto-server-srp
journalctl -u assetto-server-srp -f | grep -v -E "reached spline end|Collision between"
journalctl -u assetto-server-srp --since today -o cat | grep "attempting to connect"   # who drove what
ss -tni | grep -A1 ":8081 "     # active CM downloads (bytes_acked)
ss -tn  | grep ":9600 "         # game connections
curl -s http://ac.xhos.dev:8081/api/details | python3 -m json.tool | head -40   # from outside
tailscale status | grep proxy-1   # tx counter = total bytes enrai→proxy-1
```

## Known issues / findings

### Download speed ≈ 38 Mbit/s

Not enrai (upload measured ~590 Mbit/s with 4 streams). proxy-1 is a
`VM.Standard.E2.1.Micro`, which (as I recall, unverified) caps internet
bandwidth around 50 Mbit/s; all downloads leave through it. Gameplay traffic is
tiny, so this only affects first-time downloads. Fix if it matters: route AC
through arashi (A1.Flex, 4 OCPU) — needs `homelab.tcpForwards` to support a
gateway other than proxy-1 plus a DNS record for arashi's IP.

### Low FPS on vyverne (Linux) vs friends on Windows

Measured: on the server, VRAM 11.7/12 GB (acs.exe 8.8 GB; 6.5 GB solo), GPU at
"100%" but only ~100 W of ~170 W → stalled on memory. NVIDIA's Linux driver
handles VRAM oversubscription far worse than Windows WDDM, and DXVK uses a bit
more VRAM than native D3D11. A friend with an 8 GB AMD card on Windows gets
80–90 fps on the same server. The car list was trimmed from 39 to 13 player
models (79 → 53 entries) to reduce this; **not yet re-measured**. Other levers:
close GPU apps (Discord/browser), lower shadows/reflections/CSP effects, fewer
traffic models. Also note Pure previously cost ~13 fps (see
`misc/assetto-corsa.md`) — the server enables WeatherFX.

### Westyasha keeps getting kicked

Timeline of his last attempt: TCP handshake OK → CSP handshake and chat OK →
kicked 15 s after his first UDP position update with "has not sent a ping
response for over 15 seconds". TCP works both ways; UDP from server to him
never arrives (or his replies never leave). Same path works for xhos and Dyse,
so it's on his side. RTT to him ~150–190 ms. Suggested to him: allow `acs.exe`
in Windows Firewall for Private + Public and delete any inbound **block** rules
for it; try without VPN/"game booster"; try a phone hotspot; otherwise get his
`Documents\Assetto Corsa\logs\log.txt` after a kick. Unresolved as of writing.

**Workaround (2026-09-24): ZeroTier.** Westyasha's ISP won't pass UDP to
Oracle. enrai now joins the old gaming ZeroTier network `abfd31bd47fb27ef`
(`services.zerotierone` in `systems/enrai/configuration.nix`, state persisted
in `/var/lib/zerotier-one`). The instance has `allowedInterfaces = ["zt*"]`,
which opens 9600/tcp+udp and 8081/tcp on ZeroTier interfaces; UDP 9993 is open
for direct peer connections. Setup: authorize enrai in ZeroTier Central, get its
ZT IP (`ip -4 addr show | grep -A2 zt`), friend joins with
`acmanager://race/online/join?ip=<enrai zt ip>&httpPort=8081`. Check the path is
direct with `sudo zerotier-cli peers` on enrai (look for DIRECT, not RELAY).

### The two "crashes" at 20:37:41 / 20:38:17

Not crashes: SIGKILL, no kernel OOM, no systemd action. A root `sudo btop` was
opened on enrai at 20:37:37 — most likely killed from there. If it recurs with
nobody in btop, investigate again.

### Deploy failures that weren't the server

- `sops-install-secrets ... is not a string` → quote the password in sops.
- `sops-proton-pass-sync.service` failing → `pass-cli login` on enrai (as xhos).

## Upstream

- AssettoServer: https://github.com/compujuckel/AssettoServer (docs: https://assettoserver.org)
- Content Manager source (for CM behaviour questions): https://github.com/gro-ove/actools
  — download URLs built in `AcManager.Tools/Managers/Online/ServerEntry.Extended.cs`,
  install confirmation in `AcManager.Tools/ContentInstallation/ContentInstallationEntry.cs`.
