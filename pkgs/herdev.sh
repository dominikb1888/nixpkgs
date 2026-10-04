set -euo pipefail

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  cat <<'EOF'
Usage: herdev [stop]

Start or attach to this directory's Herdr session and local LLM services.
Use `herdev stop` to stop the session and services owned by herdev.
EOF
  exit 0
fi
if [[ $# -gt 0 && "$1" != stop ]]; then
  echo "Usage: herdev [stop]" >&2
  exit 2
fi

model="${HERDEV_OLLAMA_MODEL:-qwen3-coder:30b-a3b-q8_0}"
api_key="sk-herdev-local"

project_dir="$(pwd -P)"
project_name="$(basename "$project_dir" | tr -cs '[:alnum:]_-' '-')"
project_hash="$(printf '%s' "$project_dir" | sha256sum | cut -c1-8)"
session_name="${HERDEV_SESSION_NAME:-herdev-$project_name-$project_hash}"
default_port_hash="${project_hash:0:4}"
default_port=$((40000 + 16#$default_port_hash % 20000))
port="${HERDEV_LITELLM_PORT:-$default_port}"
runtime_root="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/herdev-$(id -u)"
runtime_dir="$runtime_root/$project_hash"
mkdir -p "$runtime_dir"
chmod 700 "$runtime_root" "$runtime_dir"

if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
  echo "herdev: HERDEV_LITELLM_PORT must be a TCP port from 1 to 65535" >&2
  exit 2
fi
export OLLAMA_HOST=http://127.0.0.1:11434

ollama_pidfile="$runtime_root/ollama.pid"
litellm_pidfile="$runtime_dir/litellm.pid"

stop_owned_process() {
  local pidfile="$1"
  local pid started current

  [[ -f "$pidfile" ]] || return 0
  pid="$(sed -n '1p' "$pidfile")"
  started="$(sed -n '2p' "$pidfile")"
  if [[ -z "$pid" || -z "$started" ]]; then
    rm -f "$pidfile"
    return 0
  fi
  current="$(ps -p "$pid" -o lstart= 2>/dev/null | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  if [[ "$current" == "$started" ]]; then
    kill -TERM "$pid" 2>/dev/null || true
    for _ in $(seq 1 10); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
    if kill -0 "$pid" 2>/dev/null; then
      current="$(ps -p "$pid" -o lstart= 2>/dev/null | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
      if [[ "$current" == "$started" ]]; then
        kill -KILL "$pid"
      fi
    fi
  fi
  rm -f "$pidfile"
}

record_process() {
  local pid="$1"
  local pidfile="$2"
  local started
  started="$(ps -p "$pid" -o lstart= | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  printf '%s\n%s\n' "$pid" "$started" > "$pidfile"
}

if [[ "${1:-}" == stop ]]; then
  shift
  if (($#)); then
    echo "Usage: herdev stop" >&2
    exit 2
  fi

  session_exists="$(
    herdr session list --json |
      jq --arg session "$session_name" '[.sessions[] | select(.name == $session)] | length'
  )"
  if [[ "$session_exists" != 0 ]]; then
    herdr session stop "$session_name"
  fi
  stop_owned_process "$litellm_pidfile"
  active_herdev_sessions="$(
    herdr session list --json |
      jq --arg session "$session_name" \
        '[.sessions[] | select(.name != $session and .running and (."default" != true))] | length'
  )"
  if [[ "$active_herdev_sessions" == 0 ]]; then
    stop_owned_process "$ollama_pidfile"
  fi
  echo "herdev: stopped session '$session_name' and its owned services"
  exit 0
fi

if [[ ! "$model" =~ ^[[:alnum:]_.:/-]+$ ]]; then
  echo "herdev: invalid HERDEV_OLLAMA_MODEL: $model" >&2
  exit 2
fi

ollama_ready() {
  curl -fsS --max-time 2 http://127.0.0.1:11434/api/version >/dev/null 2>&1
}
litellm_ready() {
  curl -fsS --max-time 2 "http://127.0.0.1:$port/health/liveliness" >/dev/null 2>&1
}

wait_for_service() {
  local label="$1"
  local pid="$2"
  local check="$3"
  local log="$4"

  for _ in $(seq 1 60); do
    if "$check"; then
      return 0
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "herdev: $label exited during startup; last log lines:" >&2
      tail -n 40 "$log" >&2 || true
      return 1
    fi
    sleep 1
  done

  echo "herdev: timed out waiting for $label; last log lines:" >&2
  tail -n 40 "$log" >&2 || true
  return 1
}

if ! ollama_ready; then
  echo "herdev: starting Ollama"
  ollama serve >"$runtime_dir/ollama.log" 2>&1 &
  ollama_pid=$!
  record_process "$ollama_pid" "$ollama_pidfile"
  wait_for_service "Ollama" "$ollama_pid" ollama_ready "$runtime_dir/ollama.log"
fi

if ! ollama show "$model" >/dev/null 2>&1; then
  echo "herdev: Ollama model '$model' is not installed; run: ollama pull '$model'" >&2
  exit 1
fi

if litellm_ready; then
  if ! curl -fsS --max-time 5 \
    -H "Authorization: Bearer $api_key" \
    "http://127.0.0.1:$port/v1/models" |
    grep -Eq '"id"[[:space:]]*:[[:space:]]*"local"'; then
    echo "herdev: LiteLLM is responding on port $port but does not expose the 'local' model." >&2
    echo "herdev: choose another port with HERDEV_LITELLM_PORT." >&2
    exit 1
  fi
else
  config="$runtime_dir/litellm.yaml"
  cat >"$config" <<EOF
model_list:
  - model_name: local
    litellm_params:
      model: ollama_chat/$model
      api_base: http://127.0.0.1:11434
general_settings:
  master_key: $api_key
EOF
  echo "herdev: starting LiteLLM on 127.0.0.1:$port"
  litellm --config "$config" --host 127.0.0.1 --port "$port" \
    >"$runtime_dir/litellm.log" 2>&1 &
  litellm_pid=$!
  record_process "$litellm_pid" "$litellm_pidfile"
  wait_for_service "LiteLLM" "$litellm_pid" litellm_ready "$runtime_dir/litellm.log"
fi

export FM_BACKEND=herdr
export FM_HOME="${FM_HOME:-$HOME/Firstmate}"
export HERDR_SKILL_PATH="${HERDR_SKILL_PATH:-$HOME/.config/herdr/agent-instructions.md}"
export FM_HARNESS=omp
export FM_OMP_HARNESS="omp --model openai/local --add-dir \"$HOME/Firstmate\""
export OPENAI_BASE_URL="http://127.0.0.1:$port/v1"
export OPENAI_API_KEY="$api_key"

echo "herdev: opening Herdr session '$session_name' in $project_dir"
herdr --session "$session_name"
