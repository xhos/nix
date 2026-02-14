{pkgs}:
pkgs.writeShellApplication {
  name = "whspr";
  runtimeInputs = with pkgs; [
    whisper-ctranslate2
    sox
    wl-clipboard
    coreutils
  ];
  text = ''
    DIR="/tmp/whisper-dictate"
    REC_PID="$DIR/recording.pid"
    SOX_PID="$DIR/sox.pid"
    TRN_FLAG="$DIR/transcribing.flag"
    STOP_FLAG="$DIR/stop.flag"
    CHUNK_DIR="$DIR/chunks"
    RESULT="$DIR/result.txt"
    LOG="$DIR/debug.log"

    mkdir -p "$DIR"

    log() {
      echo "[$(date '+%H:%M:%S.%3N')] $*" >> "$LOG"
    }

    # already finalizing, ignore
    if [[ -f "$STOP_FLAG" ]]; then
      exit 0
    fi

    # stop
    if [[ -f "$REC_PID" && -s "$REC_PID" ]] && kill -0 "$(cat "$REC_PID")" 2>/dev/null; then
      touch "$STOP_FLAG"
      touch "$TRN_FLAG"
      if [[ -f "$SOX_PID" && -s "$SOX_PID" ]] && kill -0 "$(cat "$SOX_PID")" 2>/dev/null; then
        kill "$(cat "$SOX_PID")" 2>/dev/null || true
      fi
      echo "" >> "$LOG"
      log "--- STOP PRESSED ---"
      notify-send "whisper" "finalizing..." -t 1500
      exit 0
    fi

    # start
    rm -rf "$CHUNK_DIR" "$STOP_FLAG" "$TRN_FLAG" "$RESULT"
    mkdir -p "$CHUNK_DIR"
    : > "$LOG"
    log "--- SESSION START ---"
    notify-send "whisper" "recording..." -t 1500

    (
      i=0
      whisper_pid=""

      while [[ ! -f "$STOP_FLAG" ]]; do
        chunk="$CHUNK_DIR/chunk_$(printf '%04d' $i).wav"

        log "chunk $i: recording..."
        sox -q -v 0.7 -d -r 16000 -c 1 -b 16 "$chunk" \
          silence 1 0.1 5% 1 0.5 5%
        sox_pid=$!
        echo "$sox_pid" > "$SOX_PID"
        wait "$sox_pid" 2>/dev/null || true

        if [[ ! -s "$chunk" ]] || [[ $(stat -c%s "$chunk") -lt 10000 ]]; then
          log "chunk $i: too small ($(stat -c%s "$chunk" 2>/dev/null || echo 0) bytes), skipped"
          rm -f "$chunk"
          continue
        fi

        duration=$(sox "$chunk" -n stat 2>&1 | grep "Length" | awk '{print $3}')
        log "chunk $i: recorded ''${duration}s ($(stat -c%s "$chunk") bytes)"

        if [[ -n "$whisper_pid" ]]; then
          log "chunk $i: waiting for previous transcription..."
          wait "$whisper_pid" 2>/dev/null || true
          log "chunk $i: previous transcription done"
        fi

        log "chunk $i: transcribing..."
        whisper-ctranslate2 "$chunk" \
          --model large-v3 \
          --device cuda --compute_type float16 \
          --output_format txt --output_dir "$CHUNK_DIR" &
        whisper_pid=$!

        i=$((i + 1))
      done

      log "stop flag detected, finishing up"

      if [[ -n "$whisper_pid" ]]; then
        log "waiting for last background transcription..."
        wait "$whisper_pid" 2>/dev/null || true
        log "last background transcription done"
      fi

      last_chunk="$CHUNK_DIR/chunk_$(printf '%04d' $i).wav"
      if [[ -s "$last_chunk" ]] && [[ $(stat -c%s "$last_chunk") -ge 10000 ]]; then
        duration=$(sox "$chunk" -n stat 2>&1 | grep "Length" | awk '{print $3}')
        log "chunk $i: recorded ''${duration}s ($(stat -c%s "$chunk") bytes)"
        whisper-ctranslate2 "$last_chunk" \
          --model large-v3 \
          --device cuda --compute_type float16 \
          --output_format txt --output_dir "$CHUNK_DIR"
        log "final transcription done"
      else
        log "no usable final chunk"
      fi

      : > "$RESULT"
      for txt in "$CHUNK_DIR"/chunk_*.txt; do
        [[ -f "$txt" && -s "$txt" ]] && cat "$txt" >> "$RESULT"
      done

      log "--- SESSION END ---"
      log "total chunks: $i"
      log "result: $(wc -c < "$RESULT" 2>/dev/null || echo 0) bytes"

      if [[ -s "$RESULT" ]]; then
        wl-copy < "$RESULT"
        notify-send "whisper" "copied to clipboard" -t 2000
      else
        notify-send "whisper" "no speech detected" -t 2000
      fi

      rm -rf "$CHUNK_DIR" "$RESULT" "$STOP_FLAG" "$TRN_FLAG" "$SOX_PID" "$REC_PID"
    ) &
    echo $! > "$REC_PID"
  '';
}
