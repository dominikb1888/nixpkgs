#!/usr/bin/env bash
# Claude Code status line with Starship integration
# Format: [Starship prompt] │ Model │ $Cost │ Context% │ Rate limits (adaptive)

set -euo pipefail

input=$(cat)
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
MODEL=$(echo "$input" | jq -r '.model.display_name')
PERCENT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size')
USAGE=$(echo "$input" | jq '.context_window.current_usage')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Token counts for "Xk/Yk" display
if [ "$USAGE" != "null" ]; then
  CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
else
  CURRENT_TOKENS=0
fi
CURRENT_K=$((CURRENT_TOKENS / 1000))
SIZE_K=$((CONTEXT_SIZE / 1000))

# Circle slice icons (nf-md-circle_slice_1 through 8)
# Maps percentage to progressively filling circle
if   [ "$PERCENT" -lt 13 ]; then ICON="󰪞"
elif [ "$PERCENT" -lt 25 ]; then ICON="󰪟"
elif [ "$PERCENT" -lt 38 ]; then ICON="󰪠"
elif [ "$PERCENT" -lt 50 ]; then ICON="󰪡"
elif [ "$PERCENT" -lt 63 ]; then ICON="󰪢"
elif [ "$PERCENT" -lt 75 ]; then ICON="󰪣"
elif [ "$PERCENT" -lt 88 ]; then ICON="󰪤"
else ICON="󰪥"
fi

# Color by percentage: green <50%, yellow 50-75%, orange 75-90%, red 90%+
color_for_percent() {
  local pct=$1
  if   [ "$pct" -lt 50 ]; then printf "\033[32m"              # green
  elif [ "$pct" -lt 75 ]; then printf "\033[33m"              # yellow
  elif [ "$pct" -lt 90 ]; then printf "\033[38;2;213;100;0m"  # orange (#D56400)
  else printf "\033[31m"                                       # red
  fi
}

RESET="\033[0m"
CTX_COLOR=$(color_for_percent "$PERCENT")

# Format cost as $X.XX
COST_FMT=$(printf '$%.2f' "$COST")

# Rate limits (adaptive: hidden <50%, shown with color >=50%, reset timer >=90%)
NOW=$(date +%s)
RATE_PARTS=""

for window in five_hour seven_day; do
  PCT=$(echo "$input" | jq -r ".rate_limits.${window}.used_percentage // empty")
  [ -z "$PCT" ] && continue
  [ "$PCT" -lt 50 ] && continue

  RESETS_AT=$(echo "$input" | jq -r ".rate_limits.${window}.resets_at")
  if [ "$window" = "five_hour" ]; then LABEL="5h"; else LABEL="7d"; fi

  CLR=$(color_for_percent "$PCT")
  PART="${CLR}${LABEL}:${PCT}%"

  # Show reset timer when >=90%
  if [ "$PCT" -ge 90 ]; then
    MINS=$(( (RESETS_AT - NOW) / 60 ))
    if [ "$MINS" -lt 0 ]; then MINS=0; fi
    PART="${PART} ↻${MINS}m"
  fi

  PART="${PART}${RESET}"
  if [ -n "$RATE_PARTS" ]; then
    RATE_PARTS="${RATE_PARTS} · ${PART}"
  else
    RATE_PARTS="$PART"
  fi
done

# Starship prompt (line 2 has content, line 1 is clear-screen, line 3 is prompt char)
# Strip leading shlvl indicator (e.g., " 3" showing shell depth)
STARSHIP=$(starship prompt -p "$DIR" 2>/dev/null | sed -n '2p' | sed 's/^\x1b\[[0-9;]*m[^[]*\x1b\[0m //')

# Build output: [Starship] 󰚩 Model · Context [· $Cost] [· Rate limits]
OUTPUT=$(printf "%s  󰚩 %s · ${CTX_COLOR}%s %dk/%dk (%d%%)${RESET}" \
  "$STARSHIP" "$MODEL" "$ICON" "$CURRENT_K" "$SIZE_K" "$PERCENT")

TAIL=""
if [ "$(echo "$COST > 0" | bc)" -eq 1 ]; then
  TAIL=" · ${COST_FMT}"
fi
if [ -n "$RATE_PARTS" ]; then
  TAIL="${TAIL} · $(printf "%b" "$RATE_PARTS")"
fi

printf "%s%s" "$OUTPUT" "$TAIL"
