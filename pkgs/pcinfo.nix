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
    [ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

    STRESS=0
    [ "$1" = "-s" ] && STRESS=''${2:-60}

    B=$'\e[1m' D=$'\e[2m' C=$'\e[36m' G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' N=$'\e[0m'
    row()  { printf '%s%-5s%s %s\n' "$C" "$1" "$N" "$2"; }
    sub()  { printf '      %s\n' "$1"; }
    dmi()  { cat "/sys/class/dmi/id/$1" 2>/dev/null | tr -d '\0' | xargs; }
    ok()   { printf '%s%s%s' "$G" "$1" "$N"; }
    warn() { printf '%s%s%s' "$Y" "$1" "$N"; }
    bad()  { printf '%s%s%s' "$R" "$1" "$N"; }
    isnum() { [[ $1 =~ ^[0-9]+$ ]]; }

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
      local h
      for h in /sys/class/hwmon/hwmon*; do
        case "$(cat "$h/name" 2>/dev/null)" in
          coretemp|k10temp|zenpower|cpu_thermal)
            echo $(( $(cat "$h/temp1_input") / 1000 )); return ;;
        esac
      done
      echo "?"
    }

    fans() {
      cat /sys/class/hwmon/hwmon*/fan*_input 2>/dev/null |
        awk '$1>0{printf "%s%d", (n++?"/":""), $1} END{printf (n ? " rpm" : "n/a")}'
    }

    clock_mhz() { awk '/^cpu MHz/{s+=$4;n++} END{printf "%d", (n ? s/n : 0)}' /proc/cpuinfo; }

    temp_col() {
      isnum "$1" || { printf '%s' "$1"; return; }
      if   [ "$1" -ge 95 ]; then bad "$1°C"
      elif [ "$1" -ge 85 ]; then warn "$1°C"
      else ok "$1°C"; fi
    }

    clear

    # ── header ──────────────────────────────────────────────
    tag=$(dmi product_serial)
    printf '%s%s %s%s  %s| %s | S/N %s%s\n' \
      "$B" "$(dmi sys_vendor)" "$(dmi product_name)" "$N" "$D" "$(chassis)" "''${tag:-?}" "$N"
    printf '%sBIOS %s (%s) | %s%s\n\n' \
      "$D" "$(dmi bios_version)" "$(dmi bios_date)" "$(date '+%F %H:%M')" "$N"

    # ── CPU ─────────────────────────────────────────────────
    cpu=$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo |
          sed -E 's/\((R|TM|tm)\)//g; s/ CPU / /; s/ +/ /g')
    cores=$(lscpu -p=core,socket | grep -v '^#' | sort -u | wc -l)
    maxf=$(lscpu | awk -F': *' '/CPU max MHz/{printf "%.1f GHz", $2/1000}')
    row CPU "$B$cpu$N"
    sub "''${cores}C/$(nproc)T | max ''${maxf:-?} | idle $(temp_col "$(cpu_temp)") | fans $(fans)"

    # ── RAM ─────────────────────────────────────────────────
    read -r mtype mspeed used total sizes < <(dmidecode -t 17 2>/dev/null | awk -F': ' '
      /^\tSize:/ { t++; if ($2 ~ /No Module|Not Installed/) s = s "-- ";
                   else { u++; v = $2; gsub(/ |B$/, "", v); s = s v " " } }
      /^\tType:/ && !ty && $2 !~ /Unknown|Other/                 { ty = $2 }
      /^\tSpeed:/ && !sp && $2 ~ /[0-9]/                          { sp = $2 }
      /^\tConfigured (Memory|Clock) Speed:/ && !cs && $2 ~ /[0-9]/ { cs = $2 }
      END { gsub(/ /, "", cs); gsub(/ /, "", sp);
            print (ty ? ty : "?"), (cs ? cs : (sp ? sp : "?")), u+0, t+0, s }')
    memtot=$(awk '/MemTotal/{printf "%.1f GiB", $2/1048576}' /proc/meminfo)
    row RAM "$B$memtot$N ''${mtype:-?} @ ''${mspeed:-?}"
    [ "''${total:-0}" -gt 0 ] && sub "slots $used/$total used: $sizes"

    # ── disks ───────────────────────────────────────────────
    bootdev=$(lsblk -no PKNAME "$(findmnt -no SOURCE /iso 2>/dev/null)" 2>/dev/null | head -1)
    first=1
    for d in $(lsblk -dbno NAME,TYPE,SIZE | awk '$2=="disk" && $3>0 && $1!~/^(zram|ram)/{print $1}'); do
      [ "$d" = "$bootdev" ] && continue
      model=$(lsblk -dno MODEL "/dev/$d" | xargs | cut -c1-24)
      size=$(lsblk -dno SIZE "/dev/$d" | xargs)
      tran=$(lsblk -dno TRAN "/dev/$d" | xargs)
      IFS=$'\t' read -r passed hours temp wear real pend merr < <(
        smartctl -j -a "/dev/$d" 2>/dev/null | jq -r '[
          (if .smart_status.passed == null then "?" else .smart_status.passed end),
          (.power_on_time.hours // "?"),
          (.temperature.current // "?"),
          (.nvme_smart_health_information_log.percentage_used // "-"),
          ((.ata_smart_attributes.table // []) | map(select(.id==5))   | .[0].raw.value // "-"),
          ((.ata_smart_attributes.table // []) | map(select(.id==197)) | .[0].raw.value // "-"),
          (.nvme_smart_health_information_log.media_errors // "-")
        ] | map(tostring) | @tsv')

      case "$passed" in
        true)  h=$(ok PASS) ;;
        false) h=$(bad FAIL) ;;
        *)     h=$(warn "no SMART") ;;
      esac
      passed=''${passed:-?}; hours=''${hours:-?}
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

      line=$(printf '%-8s %-24s %6s %-5s %s %s' "$d" "''${model:-?}" "$size" "''${tran:-?}" "$h" "$extra")
      if [ $first -eq 1 ]; then row DISK "$line"; first=0; else sub "$line"; fi
    done
    [ $first -eq 1 ] && row DISK "$(warn "none found")"

    # ── GPU ─────────────────────────────────────────────────
    first=1
    while read -r g; do
      [ -z "$g" ] && continue
      if [ $first -eq 1 ]; then row GPU "$g"; first=0; else sub "$g"; fi
    done < <(lspci 2>/dev/null | grep -E 'VGA|3D|Display' |
             sed -E 's/^[^ ]+ [^:]+: //; s/ Corporation//; s/ \(rev [^)]*\)//' | cut -c1-80)

    # ── network ─────────────────────────────────────────────
    first=1
    for n in /sys/class/net/*; do
      [ -e "$n/device" ] || continue
      i=''${n##*/}
      name=$(lspci -s "$(basename "$(readlink -f "$n/device")")" 2>/dev/null |
             sed -E 's/^[^ ]+ [^:]+: //; s/ Corporation//; s/ \(rev [^)]*\)//' | cut -c1-48)
      sp=$(cat "$n/speed" 2>/dev/null)
      if isnum "$sp" && [ "$sp" -gt 0 ]; then link=$(ok "''${sp}Mb/s"); else link=$(cat "$n/operstate"); fi
      [ -d "$n/wireless" ] && link="wifi $link"
      line=$(printf '%-9s %-48s %s %s' "$i" "''${name:-?}" "$(cat "$n/address")" "$link")
      if [ $first -eq 1 ]; then row NET "$line"; first=0; else sub "$line"; fi
    done

    # ── battery (laptops) ───────────────────────────────────
    for b in /sys/class/power_supply/BAT*; do
      full=$(cat "$b/energy_full" 2>/dev/null || cat "$b/charge_full" 2>/dev/null)
      design=$(cat "$b/energy_full_design" 2>/dev/null || cat "$b/charge_full_design" 2>/dev/null)
      isnum "$full" && isnum "$design" && [ "$design" -gt 0 ] || continue
      hp=$(( full * 100 / design ))
      hs="health ''${hp}%"; [ "$hp" -lt 80 ] && hs=$(warn "$hs"); [ "$hp" -lt 60 ] && hs=$(bad "$hs")
      row BATT "$hs | cycles $(cat "$b/cycle_count" 2>/dev/null || echo ?)"
    done

    # ── stress test ─────────────────────────────────────────
    if isnum "$STRESS" && [ "$STRESS" -gt 0 ]; then
      echo
      stress-ng --cpu 0 --timeout "''${STRESS}s" >/dev/null 2>&1 &
      pid=$!; maxt="?"; minc=999999; sumc=0; k=0; maxfan=""
      while kill -0 "$pid" 2>/dev/null; do
        sleep 1
        t=$(cpu_temp); c=$(clock_mhz)
        isnum "$t" && { ! isnum "$maxt" || [ "$t" -gt "$maxt" ]; } && maxt=$t
        k=$((k + 1)); sumc=$((sumc + c)); [ "$c" -lt "$minc" ] && minc=$c
        maxfan=$(fans)
        printf '\r%sstressing %d/%ss  %s°C  %s MHz%s\e[K' "$D" "$k" "$STRESS" "$t" "$c" "$N"
      done
      printf '\r\e[K'
      avg=$(( k > 0 ? sumc / k : 0 ))
      row LOAD "''${STRESS}s all cores | max $(temp_col "$maxt") | clock avg $(awk -v a="$avg" 'BEGIN{printf "%.2f", a/1000}') GHz (min $(awk -v m="$minc" 'BEGIN{printf "%.2f", m/1000}')) | fans $maxfan"
    fi
    echo
  '';
}
