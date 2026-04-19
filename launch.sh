#!/usr/bin/env bash
# launch.sh — single entrypoint that brings up every long-running service Foul
# Ward needs: Cursor IDE, Godot editor (mono build), the RAG MCP server, and
# (when installed) the ComfyUI backend used by the gen3d pipeline.
#
# WHY THIS SCRIPT EXISTS
#   Several services normally hijack a terminal window when you run them in the
#   foreground (RAG MCP, ComfyUI, godot_net). This wrapper puts each one in its
#   own `tmux` window inside a session called `foulward`, so a single shell can
#   start everything and live logs stay one keystroke away.
#
# USAGE
#   ./launch.sh              — start any service that is not already running
#   ./launch.sh status       — show what is up / down (no changes)
#   ./launch.sh attach       — attach to the tmux session (Ctrl-b d to detach)
#   ./launch.sh stop         — kill the tmux session and the GUI processes
#   ./launch.sh restart      — stop then start
#
# OPTIONAL ENV (override defaults; never commit secrets):
#   FOULWARD_COMFYUI_HOME    default: $HOME/ComfyUI
#   FOULWARD_COMFYUI_PORT    default: 8188
#   FOULWARD_RAG_VENV        default: $HOME/LLM/rag_env
#   FOULWARD_RAG_SERVER      default: $HOME/LLM/rag_mcp_server.py
#   FOULWARD_GODOT_BIN       default: <repo>/Godot_v4.6.2-stable_mono_linux.x86_64
#   FOULWARD_CURSOR_BIN      default: cursor (resolved via PATH)
#   FOULWARD_SECRETS_FILE    default: $HOME/.foulward_secrets
#       — sourced if it exists (e.g. export MIXAMO_EMAIL=..., HF_TOKEN=hf_...).
#
# Idempotent: re-running this script only (re-)starts services that are down.

set -euo pipefail

# ── Resolve repo root regardless of where the user ran the script from ──────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SESSION="foulward"
LOG_DIR="${REPO_ROOT}/.launch-logs"
mkdir -p "${LOG_DIR}"

# ── Config (env-overridable) ────────────────────────────────────────────────
COMFYUI_HOME="${FOULWARD_COMFYUI_HOME:-${HOME}/ComfyUI}"
COMFYUI_PORT="${FOULWARD_COMFYUI_PORT:-8188}"
RAG_VENV="${FOULWARD_RAG_VENV:-${HOME}/LLM/rag_env}"
RAG_SERVER="${FOULWARD_RAG_SERVER:-${HOME}/LLM/rag_mcp_server.py}"
GODOT_BIN="${FOULWARD_GODOT_BIN:-${REPO_ROOT}/Godot_v4.6.2-stable_mono_linux.x86_64}"
CURSOR_BIN="${FOULWARD_CURSOR_BIN:-cursor}"
SECRETS_FILE="${FOULWARD_SECRETS_FILE:-${HOME}/.foulward_secrets}"

# Source secrets (Mixamo, Hugging Face token for gen3d/TRELLIS, etc.) if the user
# keeps them in a file outside the repo. We re-export them so child tmux panes inherit.
if [[ -r "${SECRETS_FILE}" ]]; then
  # shellcheck disable=SC1090
  set -a; source "${SECRETS_FILE}"; set +a
fi

# ── Pretty logging helpers ──────────────────────────────────────────────────
c_ok()    { printf "\033[32m%s\033[0m\n" "$*"; }
c_warn()  { printf "\033[33m%s\033[0m\n" "$*"; }
c_err()   { printf "\033[31m%s\033[0m\n" "$*"; }
c_info()  { printf "\033[36m%s\033[0m\n" "$*"; }

# ── Probes ──────────────────────────────────────────────────────────────────
have() { command -v "$1" >/dev/null 2>&1; }

cursor_running() { pgrep -fa "/cursor( |$)" >/dev/null 2>&1 || pgrep -f "/opt/cursor/" >/dev/null 2>&1; }
godot_running()  { pgrep -fa "Godot_v4\.6\.2.*FoulWard" >/dev/null 2>&1; }
rag_running()    { pgrep -fa "rag_mcp_server\.py" >/dev/null 2>&1; }
port_listening() { ss -ltn "sport = :$1" 2>/dev/null | tail -n +2 | grep -q .; }
comfy_running()  { port_listening "${COMFYUI_PORT}"; }

tmux_session_alive() { tmux has-session -t "${SESSION}" 2>/dev/null; }

# Create the tmux session lazily, attached to no window we care about.
ensure_tmux_session() {
  if tmux_session_alive; then return; fi
  # The placeholder window is renamed/replaced as real services come up.
  tmux new-session -d -s "${SESSION}" -n "_init" "echo 'foulward launcher'; sleep infinity"
}

# Spawn a service in its own tmux window. Args: <window_name> <shell command>.
spawn_window() {
  local name="$1"; shift
  local cmd="$*"
  ensure_tmux_session
  if tmux list-windows -t "${SESSION}" -F '#{window_name}' | grep -Fxq "${name}"; then
    return  # already up
  fi
  # Tee logs so `attach` shows live output AND we get a persistent file.
  local logfile="${LOG_DIR}/${name}.log"
  tmux new-window -t "${SESSION}" -n "${name}" \
    "bash -lc '{ ${cmd}; } 2>&1 | tee -a \"${logfile}\"'"
}

# ── Service starters ────────────────────────────────────────────────────────
start_cursor() {
  if cursor_running; then c_ok "[cursor]   already running"; return; fi
  if ! have "${CURSOR_BIN}" && [[ "${CURSOR_BIN}" == "cursor" ]] && [[ ! -x /opt/cursor/usr/bin/cursor ]]; then
    c_warn "[cursor]   binary not found (set FOULWARD_CURSOR_BIN); skipping"
    return
  fi
  local bin="${CURSOR_BIN}"
  if ! have "${bin}" && [[ -x /opt/cursor/usr/bin/cursor ]]; then bin="/opt/cursor/usr/bin/cursor"; fi
  c_info "[cursor]   launching detached"
  nohup "${bin}" >"${LOG_DIR}/cursor.log" 2>&1 &
  disown
}

start_godot() {
  if godot_running; then c_ok "[godot]    already running"; return; fi
  if [[ ! -x "${GODOT_BIN}" ]]; then
    c_warn "[godot]    binary not executable: ${GODOT_BIN} — skipping"
    return
  fi
  c_info "[godot]    launching editor on ${REPO_ROOT}"
  nohup "${GODOT_BIN}" -e --path "${REPO_ROOT}" >"${LOG_DIR}/godot.log" 2>&1 &
  disown
}

start_rag() {
  if rag_running; then c_ok "[rag]      already running"; return; fi
  if [[ ! -d "${RAG_VENV}" ]] || [[ ! -f "${RAG_SERVER}" ]]; then
    c_warn "[rag]      venv or server missing (${RAG_VENV} / ${RAG_SERVER}) — skipping"
    return
  fi
  c_info "[rag]      starting in tmux window 'rag'"
  spawn_window "rag" \
    "source \"${RAG_VENV}/bin/activate\" && exec python \"${RAG_SERVER}\""
}

start_comfyui() {
  if comfy_running; then c_ok "[comfyui]  already listening on :${COMFYUI_PORT}"; return; fi
  if [[ ! -f "${COMFYUI_HOME}/main.py" ]]; then
    c_warn "[comfyui]  not installed at ${COMFYUI_HOME} — skipping"
    c_warn "           install per docs/gen3d_workplan.md, or set FOULWARD_COMFYUI_HOME"
    return
  fi
  c_info "[comfyui]  starting in tmux window 'comfyui' (port ${COMFYUI_PORT})"
  # Workplan uses `.venv` under ComfyUI; also accept `venv` for older setups.
  local activate=""
  if [[ -f "${COMFYUI_HOME}/.venv/bin/activate" ]]; then
    activate="source \"${COMFYUI_HOME}/.venv/bin/activate\" && "
  elif [[ -f "${COMFYUI_HOME}/venv/bin/activate" ]]; then
    activate="source \"${COMFYUI_HOME}/venv/bin/activate\" && "
  fi
  spawn_window "comfyui" \
    "cd \"${COMFYUI_HOME}\" && ${activate}exec python main.py --listen 127.0.0.1 --port ${COMFYUI_PORT}"
}

# ── Subcommands ─────────────────────────────────────────────────────────────
cmd_status() {
  printf "%-10s %s\n" "service" "state"
  printf "%-10s %s\n" "----------" "-----"
  cursor_running && printf "%-10s %s\n" "cursor"  "up"   || printf "%-10s %s\n" "cursor"  "down"
  godot_running  && printf "%-10s %s\n" "godot"   "up"   || printf "%-10s %s\n" "godot"   "down"
  rag_running    && printf "%-10s %s\n" "rag"     "up"   || printf "%-10s %s\n" "rag"     "down"
  comfy_running  && printf "%-10s %s (port %s)\n" "comfyui" "up" "${COMFYUI_PORT}" \
                  || printf "%-10s %s (port %s)\n" "comfyui" "down" "${COMFYUI_PORT}"
  if tmux_session_alive; then
    echo
    c_info "tmux session '${SESSION}' windows:"
    tmux list-windows -t "${SESSION}" -F "  #{window_index}: #{window_name}"
    echo "  attach: ./launch.sh attach   (or: tmux attach -t ${SESSION})"
  fi
}

cmd_attach() {
  if ! tmux_session_alive; then c_err "no tmux session '${SESSION}' — run ./launch.sh first"; exit 1; fi
  exec tmux attach -t "${SESSION}"
}

cmd_stop() {
  c_info "stopping background services…"
  if tmux_session_alive; then
    tmux kill-session -t "${SESSION}" || true
    c_ok "tmux session killed"
  fi
  # GUIs are detached from tmux — kill them by pattern.
  pkill -f "Godot_v4\.6\.2.*FoulWard" 2>/dev/null && c_ok "godot stopped" || true
  # Cursor is left alone by default; uncomment if you really want to close it.
  # pkill -f "/opt/cursor/" 2>/dev/null && c_ok "cursor stopped" || true
  c_warn "cursor left running (close manually if desired)"
}

cmd_start() {
  c_info "Foul Ward launcher — repo: ${REPO_ROOT}"
  start_cursor
  start_godot
  start_rag
  start_comfyui
  echo
  cmd_status
  echo
  c_ok "done. Attach to background services with:  ./launch.sh attach"
}

case "${1:-start}" in
  start)   cmd_start ;;
  status)  cmd_status ;;
  attach)  cmd_attach ;;
  stop)    cmd_stop ;;
  restart) cmd_stop; sleep 1; cmd_start ;;
  -h|--help|help)
    sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//' | head -n -1
    ;;
  *) c_err "unknown subcommand: $1"; echo "try: start | status | attach | stop | restart"; exit 2 ;;
esac
