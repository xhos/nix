{
  config,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;

  # glamour theme so `cull help` matches the system colors, not charm's pink
  helpTheme = pkgs.writeText "cull-help-theme.json" (builtins.toJSON {
    document = {
      margin = 1;
      color = "#${colors.base06}";
    };
    heading = {
      block_prefix = "";
      block_suffix = "\n";
      color = "#${colors.base0D}";
      bold = true;
    };
    h1 = {
      prefix = "";
      suffix = "";
    };
    h2 = {
      prefix = "";
      suffix = "";
    };
    code = {
      color = "#${colors.base0B}";
      background_color = "#${colors.base01}";
      prefix = " ";
      suffix = " ";
    };
    table = {
      center_separator = "┼";
      column_separator = "│";
      row_separator = "─";
    };
  });

  # passed with --config, so it never disturbs a personal swayimg setup
  cullLua = pkgs.writeText "cull.lua" ''
    -- swayimg reads EXIF through exiv2 and rotates on load, which is the whole
    -- reason this is not imv: portrait frames come up the right way round
    swayimg.exif_orientation = true
    swayimg.decoration = true
    swayimg.imagelist.order = "numeric"
    swayimg.imagelist.fsmon = false

    swayimg.text.font = "${config.stylix.fonts.monospace.name}"
    swayimg.text.size = 14
    swayimg.text.padding = 12
    swayimg.text.color = 0xff${colors.base06}
    swayimg.text.background = 0xc0${colors.base00}
    swayimg.text.shadow = 0x00000000
    swayimg.text.visible = true
    swayimg.text.status_timeout = 2

    swayimg.viewer.preload = 2
    swayimg.viewer.mark_color = 0xff${colors.base0B}
    swayimg.viewer.set_window_background(0xff${colors.base00})

    -- one unobtrusive line instead of swayimg's default six-line block
    swayimg.viewer.set_text("topleft", {})
    swayimg.viewer.set_text("topright", {})
    swayimg.viewer.set_text("bottomright", {})
    swayimg.viewer.set_text("bottomleft", {"{list.index}/{list.total}  {name}"})

    -- the queue is opened once and held open, so a decision costs a single
    -- write into a pipe: no process spawned on the keypress path at all
    local queue = os.getenv("CULL_QUEUE")
    local qfile = queue and io.open(queue, "a") or nil

    local function decide(mode, action, marked)
      local img = mode.get_image()
      if not img then
        return
      end
      if qfile then
        qfile:write(action, "\t", img.path, "\n")
        qfile:flush()
      end
      mode.mark_image(marked)
      swayimg.text.status = action .. "  " .. img.path:match("[^/]+$")
    end

    -- jump by index rather than stepping, so one keypress decodes one image
    local function jump(offset)
      local img = swayimg.viewer.get_image()
      if not img then
        return
      end
      local list = swayimg.imagelist.get()
      local cur
      for i, entry in ipairs(list) do
        if entry.path == img.path then
          cur = i
          break
        end
      end
      if not cur then
        return
      end
      local target = math.min(math.max(cur + offset, 1), #list)
      if target ~= cur then
        swayimg.viewer.open_path(list[target].path)
      end
    end

    swayimg.viewer.on_key("1", function()
      decide(swayimg.viewer, "keep", true)
    end)
    swayimg.viewer.on_key("2", function()
      decide(swayimg.viewer, "drop", false)
    end)
    swayimg.gallery.on_key("1", function()
      decide(swayimg.gallery, "keep", true)
    end)
    swayimg.gallery.on_key("2", function()
      decide(swayimg.gallery, "drop", false)
    end)

    -- arrows pan by default; for culling they should walk the list
    swayimg.viewer.on_key("left", function()
      swayimg.viewer.open("prev")
    end)
    swayimg.viewer.on_key("right", function()
      swayimg.viewer.open("next")
    end)
    swayimg.viewer.on_key("Shift+h", function()
      jump(-10)
    end)
    swayimg.viewer.on_key("Shift+l", function()
      jump(10)
    end)
    swayimg.viewer.on_key("Ctrl+u", function()
      jump(-25)
    end)
    swayimg.viewer.on_key("Ctrl+d", function()
      jump(25)
    end)
    swayimg.viewer.on_key("Home", function()
      swayimg.viewer.open("first")
    end)
    swayimg.viewer.on_key("End", function()
      swayimg.viewer.open("last")
    end)

    swayimg.viewer.on_key("q", function()
      swayimg.exit()
    end)
    swayimg.gallery.on_key("q", function()
      swayimg.exit()
    end)
  '';

  cull = pkgs.writeShellApplication {
    name = "cull";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.gum pkgs.swayimg];
    text = ''
      show_help() {
        gum style \
          --border rounded --border-foreground "#${colors.base0D}" \
          --foreground "#${colors.base05}" --padding "0 2" --margin "1 0" \
          "cull <source-dir> <dest-dir>" \
          "keep or drop jpegs, raw sidecars follow along"

        gum format --theme ${helpTheme} <<'HELP'
      ## culling

      | key | action                       |
      | --- | ---------------------------- |
      | `1` | keep, copy it to the dest    |
      | `2` | drop, take it back out again |

      ## moving around

      | key               | action              |
      | ----------------- | ------------------- |
      | `left` `right`    | prev / next         |
      | `H` `L`           | jump 10             |
      | `ctrl+u` `ctrl+d` | jump 25             |
      | `home` `end`      | first / last        |
      | `enter`           | thumbnail grid      |
      | `esc`             | back from the grid  |

      ## looking closer

      | key       | action                    |
      | --------- | ------------------------- |
      | `[` `]`   | rotate 90 ccw / cw        |
      | `=` `-`   | zoom in / out             |
      | `bksp`    | reset zoom and position   |
      | `m` `M`   | flip vertical/horizontal  |
      | `f` `t`   | fullscreen / text overlay |
      | `a`       | anti-aliasing             |

      ## finishing

      | key      | action                            |
      | -------- | --------------------------------- |
      | `q`      | quit, then the copies are tallied |
      | `del`    | skip, drops it from the list only |
      HELP
      }

      case "''${1:-}" in
        help | -h | --help)
          show_help
          exit 0
          ;;
      esac

      src="''${1:-}"
      dst="''${2:-}"
      if [ -z "$src" ] || [ -z "$dst" ]; then
        echo "usage: cull <source-dir> <dest-dir>   (cull help for the keys)" >&2
        exit 1
      fi
      if [ ! -d "$src" ]; then
        echo "cull: $src is not a directory" >&2
        exit 1
      fi

      mkdir -p "$dst"
      src="$(realpath "$src")"
      dst="$(realpath "$dst")"
      if [ "$src" = "$dst" ]; then
        echo "cull: source and dest are the same directory" >&2
        exit 1
      fi

      mapfile -t files < <(find "$src" -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -not -path "$dst/*" | sort)
      if [ ''${#files[@]} -eq 0 ]; then
        echo "cull: no jpegs under $src" >&2
        exit 1
      fi

      rundir="$(mktemp -d -t cull.XXXXXXXX)"
      trap 'rm -rf "$rundir"' EXIT
      CULL_QUEUE="$rundir/queue"
      export CULL_QUEUE
      mkfifo "$CULL_QUEUE"

      # keep fifo open read-write so it never blocks or hits EOF
      exec 8<>"$CULL_QUEUE"

      copy_one() {
        local s="$1" d
        d="$dst/$(basename "$s")"
        if [ -e "$d" ]; then return 0; fi
        cp "$s" "$d.part"
        mv -f "$d.part" "$d"
      }

      # single worker: no races, no parallel copies from keypress bursts
      worker() {
        local action file base stem raw
        while IFS=$'\t' read -r action file; do
          case "$action" in
            quit) break ;;
            keep)
              base="$(basename "$file")"
              raw="''${file%.*}.RAF"
              if [ -e "$dst/$base" ]; then continue; fi
              copy_one "$file"
              if [ -f "$raw" ]; then copy_one "$raw"; fi
              printf '+ %s\n' "$base"
              printf '%s\t%s\n' keep "$base" >> "$dst/.cull.log"
              ;;
            drop)
              base="$(basename "$file")"
              stem="''${base%.*}"
              if [ ! -e "$dst/$base" ]; then continue; fi
              rm -f "$dst/$base" "$dst/$base.part" "$dst/$stem.RAF" "$dst/$stem.RAF.part"
              printf -- '- %s\n' "$base"
              printf '%s\t%s\n' drop "$base" >> "$dst/.cull.log"
              ;;
          esac
        done < "$CULL_QUEUE"
      }

      worker &
      worker_pid=$!

      echo "culling ''${#files[@]} images → $dst"
      echo "  1 = keep   2 = drop   q = finish   (cull help for the rest)"
      swayimg --config ${cullLua} "''${files[@]}" || true

      # let the worker finish whatever is still queued before reporting
      printf 'quit\t\n' >&8
      wait "$worker_pid"

      kept="$(find "$dst" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) | wc -l)"
      echo "$kept images in $dst"
    '';
  };
in {
  home.packages = [cull pkgs.swayimg];
}
