# pcinfo — one-screen hardware summary for any x86 box.
# usage: pcinfo          quick report
#        pcinfo -s [N]   + N-second CPU stress test (default 60)
{pkgs}:
pkgs.writeShellApplication {
  name = "pcinfo";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gawk
    gnugrep
    gnused
    util-linux
    ncurses
    dmidecode
    smartmontools
    pciutils
    jq
    stress-ng
  ];
  # script deliberately runs without errexit/nounset; skip shellcheck nagging
  checkPhase = ":";
  text = ''
    set +euo pipefail
    shopt -s nullglob
    if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null; then exec sudo "$0" "$@"; fi

    STRESS=0
    [ "$1" = "-s" ] && STRESS=''${2:-60}

    B=$'\e[1m' D=$'\e[2m' C=$'\e[36m' G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' N=$'\e[0m'
    row()  { printf '%s%-5s%s %s\n' "$C" "$1" "$N" "$2"; }
    sub()  { printf '      %s\n' "$1"; }
    ok()   { printf '%s%s%s' "$G" "$1" "$N"; }
    warn() { printf '%s%s%s' "$Y" "$1" "$N"; }
    bad()  { printf '%s%s%s' "$R" "$1" "$N"; }
    isnum() { [[ $1 =~ ^[0-9]+$ ]]; }

    # every probe gets a deadline — sysfs/SMM/SMART reads can block forever on weird hardware
    rd()  { timeout -k 1 2 cat "$1" 2>/dev/null | tr -d '\0'; }
    t()   { local s=$1; shift; timeout -k 1 "$s" "$@" 2>/dev/null; }
    dmi() { rd "/sys/class/dmi/id/$1" | xargs; }

    # run a section in the background and abandon it if it overruns. output is buffered
    # to a file so a half-finished section never prints garbage; a process stuck in
    # uninterruptible sleep can't be killed, so we don't wait on it either.
    section() {
      local name=$1 limit=$2 fn=$3 out i=0
      out=$(mktemp) || { "$fn"; return; }
      "$fn" >"$out" 2>/dev/null &
      local pid=$!
      while kill -0 "$pid" 2>/dev/null && [ "$i" -lt $((limit * 10)) ]; do
        sleep 0.1; i=$((i + 1))
      done
      cat "$out"
      if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null
        disown "$pid" 2>/dev/null
        row "$name" "$(warn "timed out after ''${limit}s")"
      fi
      rm -f "$out"
    }

    chassis() {
      case "$(dmi chassis_type)" in
        3) echo "Desktop" ;;            4) echo "Low-profile desktop" ;;
        6) echo "Mini tower" ;;         7) echo "Tower" ;;
        8|9|10|14) echo "Laptop" ;;     13) echo "All-in-one" ;;
        15) echo "Small form factor" ;; 30|31|32) echo "Tablet/2-in-1" ;;
        35|36) echo "Mini PC" ;;        "") echo "?" ;;
        *) echo "chassis type $(dmi chassis_type)" ;;
      esac
    }

    cpu_temp() {
      local h v
      for h in /sys/class/hwmon/hwmon*; do
        case "$(rd "$h/name")" in
          coretemp|k10temp|zenpower|cpu_thermal)
            v=$(rd "$h/temp1_input")
            isnum "$v" && { echo $((v / 1000)); return; } ;;
        esac
      done
      echo "?"
    }

    # dell_smm_hwmon (optiplex etc.) is the usual offender here
    fans() {
      local f
      for f in /sys/class/hwmon/hwmon*/fan*_input; do rd "$f"; echo; done |
        awk '$1>0{printf "%s%d", (n++?"/":""), $1} END{printf (n ? " rpm" : "n/a")}'
    }

    clock_mhz() { awk '/^cpu MHz/{s+=$4;n++} END{printf "%d", (n ? s/n : 0)}' /proc/cpuinfo 2>/dev/null; }

    temp_col() {
      isnum "$1" || { printf '%s' "$1"; return; }
      if   [ "$1" -ge 95 ]; then bad "$1°C"
      elif [ "$1" -ge 85 ]; then warn "$1°C"
      else ok "$1°C"; fi
    }

    pciname() { sed -E 's/^[^ ]+ [^:]+: //; s/ Corporation//; s/ \(rev [^)]*\)//'; }

    # ── sections ────────────────────────────────────────────
    s_header() {
      local tag
      tag=$(dmi product_serial)
      printf '%s%s %s%s  %s| %s | S/N %s%s\n' \
        "$B" "$(dmi sys_vendor)" "$(dmi product_name)" "$N" "$D" "$(chassis)" "''${tag:-?}" "$N"
      printf '%sBIOS %s (%s) | %s%s\n\n' \
        "$D" "$(dmi bios_version)" "$(dmi bios_date)" "$(date '+%F %H:%M')" "$N"
    }

    s_cpu() {
      local cpu cores maxf
      cpu=$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo |
            sed -E 's/\((R|TM|tm)\)//g; s/ CPU / /; s/ +/ /g')
      cores=$(t 5 lscpu -p=core,socket | grep -v '^#' | sort -u | wc -l)
      maxf=$(t 5 lscpu | awk -F': *' '/CPU max MHz/{printf "%.1f GHz", $2/1000}')
      row CPU "$B''${cpu:-?}$N"
      sub "''${cores:-?}C/$(nproc)T | max ''${maxf:-?} | idle $(temp_col "$(cpu_temp)") | fans $(fans)"
    }

    s_ram() {
      local mtype mspeed used total sizes memtot
      read -r mtype mspeed used total sizes < <(t 5 dmidecode -t 17 | awk -F': ' '
        /^\tSize:/ { t++; if ($2 ~ /No Module|Not Installed/) s = s "-- ";
                     else { u++; v = $2; gsub(/ |B$/, "", v); s = s v " " } }
        /^\tType:/ && !ty && $2 !~ /Unknown|Other/                 { ty = $2 }
        /^\tSpeed:/ && !sp && $2 ~ /[0-9]/                          { sp = $2 }
        /^\tConfigured (Memory|Clock) Speed:/ && !cs && $2 ~ /[0-9]/ { cs = $2 }
        END { gsub(/ /, "", cs); gsub(/ /, "", sp);
              print (ty ? ty : "?"), (cs ? cs : (sp ? sp : "?")), u+0, t+0, s }')
      memtot=$(awk '/MemTotal/{printf "%.1f GiB", $2/1048576}' /proc/meminfo)
      row RAM "$B''${memtot:-?}$N ''${mtype:-?} @ ''${mspeed:-?}"
      isnum "$total" && [ "$total" -gt 0 ] && sub "slots $used/$total used: $sizes"
    }

    s_disk() {
      local bootdev first=1 d model size tran passed hours temp wear real pend merr h extra w line
      bootdev=$(t 3 lsblk -no PKNAME "$(t 3 findmnt -no SOURCE /iso)" | head -1)
      for d in $(t 5 lsblk -dbno NAME,TYPE,SIZE | awk '$2=="disk" && $3>0 && $1!~/^(zram|ram)/{print $1}'); do
        [ "$d" = "$bootdev" ] && continue
        model=$(t 3 lsblk -dno MODEL "/dev/$d" | xargs | cut -c1-24)
        size=$(t 3 lsblk -dno SIZE "/dev/$d" | xargs)
        tran=$(t 3 lsblk -dno TRAN "/dev/$d" | xargs)
        # a dying disk can stall smartctl; give each one its own budget
        IFS=$'\t' read -r passed hours temp wear real pend merr < <(
          t 15 smartctl -j -a "/dev/$d" | jq -r '[
            (if .smart_status.passed == null then "?" else .smart_status.passed end),
            (.power_on_time.hours // "?"),
            (.temperature.current // "?"),
            (.nvme_smart_health_information_log.percentage_used // "-"),
            ((.ata_smart_attributes.table // []) | map(select(.id==5))   | .[0].raw.value // "-"),
            ((.ata_smart_attributes.table // []) | map(select(.id==197)) | .[0].raw.value // "-"),
            (.nvme_smart_health_information_log.media_errors // "-")
          ] | map(tostring) | @tsv' 2>/dev/null)

        case "$passed" in
          true)  h=$(ok PASS) ;;
          false) h=$(bad FAIL) ;;
          *)     h=$(warn "no SMART") ;;
        esac
        hours=''${hours:-?}
        extra="''${hours}h"
        isnum "$hours" && [ "$hours" -ge 40000 ] && extra=$(warn "''${hours}h")
        if isnum "$wear"; then
          w="wear ''${wear}%"
          [ "$wear" -ge 50 ] && w=$(warn "$w"); [ "$wear" -ge 80 ] && w=$(bad "$w")
          extra+=" $w"
        fi
        isnum "$merr" && [ "$merr" -gt 0 ] && extra+=" $(bad "media err $merr")"
        isnum "$real" && { [ "$real" -gt 0 ] && extra+=" $(bad "realloc $real")" || extra+=" realloc 0"; }
        isnum "$pend" && [ "$pend" -gt 0 ] && extra+=" $(bad "pending $pend")"
        isnum "$temp" && extra+=" ''${temp}°C"

        line=$(printf '%-8s %-24s %6s %-5s %s %s' "$d" "''${model:-?}" "''${size:-?}" "''${tran:-?}" "$h" "$extra")
        if [ $first -eq 1 ]; then row DISK "$line"; first=0; else sub "$line"; fi
      done
      [ $first -eq 1 ] && row DISK "$(warn "none found")"
    }

    s_gpu() {
      local first=1 g
      while read -r g; do
        [ -z "$g" ] && continue
        if [ $first -eq 1 ]; then row GPU "$g"; first=0; else sub "$g"; fi
      done < <(t 5 lspci | grep -E 'VGA|3D|Display' | pciname | cut -c1-80)
      [ $first -eq 1 ] && row GPU "$(warn "none found")"
    }

    s_net() {
      local first=1 n i name sp link line
      for n in /sys/class/net/*; do
        [ -e "$n/device" ] || continue
        i=''${n##*/}
        name=$(t 3 lspci -s "$(basename "$(readlink -f "$n/device")")" | pciname | cut -c1-48)
        sp=$(rd "$n/speed")
        if isnum "$sp" && [ "$sp" -gt 0 ]; then link=$(ok "''${sp}Mb/s"); else link=$(rd "$n/operstate"); fi
        [ -d "$n/wireless" ] && link="wifi $link"
        line=$(printf '%-9s %-48s %s %s' "$i" "''${name:-?}" "$(rd "$n/address")" "''${link:-?}")
        if [ $first -eq 1 ]; then row NET "$line"; first=0; else sub "$line"; fi
      done
      [ $first -eq 1 ] && row NET "$(warn "none found")"
    }

    s_batt() {
      local b full design hp hs cyc
      for b in /sys/class/power_supply/BAT*; do
        full=$(rd "$b/energy_full"); isnum "$full" || full=$(rd "$b/charge_full")
        design=$(rd "$b/energy_full_design"); isnum "$design" || design=$(rd "$b/charge_full_design")
        isnum "$full" && isnum "$design" && [ "$design" -gt 0 ] || continue
        hp=$((full * 100 / design))
        hs="health ''${hp}%"; [ "$hp" -lt 80 ] && hs=$(warn "$hs"); [ "$hp" -lt 60 ] && hs=$(bad "$hs")
        cyc=$(rd "$b/cycle_count")
        row BATT "$hs | cycles ''${cyc:-?}"
      done
    }

    # ── report ──────────────────────────────────────────────
    clear 2>/dev/null || printf '\e[H\e[2J'

    section HOST 8  s_header
    section CPU  15 s_cpu
    section RAM  10 s_ram
    section DISK 90 s_disk
    section GPU  8  s_gpu
    section NET  10 s_net
    section BATT 8  s_batt

    # ── stress test ─────────────────────────────────────────
    if isnum "$STRESS" && [ "$STRESS" -gt 0 ]; then
      echo
      if ! command -v stress-ng >/dev/null; then
        row LOAD "$(warn "stress-ng missing")"
      else
        stress-ng --cpu 0 --timeout "''${STRESS}s" >/dev/null 2>&1 &
        pid=$!
        trap 'kill "$pid" 2>/dev/null; printf "\r\e[K"; row LOAD "$(warn aborted)"; exit 130' INT TERM
        maxt="?"; minc=999999; sumc=0; k=0; maxfan=$(fans)
        # hard stop in case stress-ng ignores its own timeout
        deadline=$((SECONDS + STRESS + 15))
        while kill -0 "$pid" 2>/dev/null && [ "$SECONDS" -lt "$deadline" ]; do
          sleep 1
          tc=$(cpu_temp); c=$(clock_mhz); isnum "$c" || c=0
          isnum "$tc" && { ! isnum "$maxt" || [ "$tc" -gt "$maxt" ]; } && maxt=$tc
          k=$((k + 1)); sumc=$((sumc + c)); [ "$c" -gt 0 ] && [ "$c" -lt "$minc" ] && minc=$c
          # fan reads are slow on some boards, don't sample every tick
          [ $((k % 10)) -eq 0 ] && maxfan=$(fans)
          printf '\r%sstressing %d/%ss  %s°C  %s MHz%s\e[K' "$D" "$k" "$STRESS" "$tc" "$c" "$N"
        done
        kill "$pid" 2>/dev/null
        trap - INT TERM
        printf '\r\e[K'
        avg=$((k > 0 ? sumc / k : 0)); [ "$minc" -eq 999999 ] && minc=0
        row LOAD "''${STRESS}s all cores | max $(temp_col "$maxt") | clock avg $(awk -v a="$avg" 'BEGIN{printf "%.2f", a/1000}') GHz (min $(awk -v m="$minc" 'BEGIN{printf "%.2f", m/1000}')) | fans $maxfan"
      fi
    fi
    echo
  '';
}
