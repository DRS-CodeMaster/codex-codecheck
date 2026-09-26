#!/usr/bin/env bash
# Codex-CodeCheck runtime — v3.0.0
# Usage:   codex-run.sh <mode> [workdir]
#   mode:    review | multi | security | optimize | mini | consult
#   workdir: directory Codex may read (default: $HOME). Sandbox is always read-only.
# Input:   $BASE/prompt.md    (task + context + absolute file paths, written by Claude)
# Output:  $BASE/out.json     (structured findings, see schema.json)
#          $BASE/status.txt   (running | done | error: ...)
#          $BASE/route.txt    (chatgpt | api:<label>)
#          $BASE/last.log     (Codex progress output)
#
# Two ways to reach Codex, tried in this order:
#   1. ChatGPT account  — `codex login` (browser). Uses your ChatGPT plan's Codex quota,
#                         no per-token API cost.
#   2. OpenAI API key   — from $BASE/config.json, $OPENAI_API_KEY, or a `codex login
#                         --with-api-key` login. Billed per token by OpenAI.
# Step 2 only runs if step 1 is unavailable (not logged in) or hits a usage/rate limit.
# Other errors (bad prompt, schema, network) do NOT fall back, so a broken run is never paid twice.
#
# Environment switches:
#   CODEX_CODECHECK_MODEL=<model>  override model (default gpt-5.6-sol or config.json "model")
#   CODEX_CODECHECK_NO_API=1       ChatGPT account only, never use an API key
#   CODEX_CODECHECK_API_ONLY=1     skip the ChatGPT account, go straight to the API key
#   CODEX_CODECHECK_HOME=<dir>     working dir (default ~/.codex-codecheck)
set -u

SELF="$0"; command -v readlink >/dev/null && SELF="$(readlink -f "$0" 2>/dev/null || echo "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"
BASE="${CODEX_CODECHECK_HOME:-$HOME/.codex-codecheck}"
MODE="${1:-review}"
WORKDIR="${2:-$HOME}"
SCHEMA="$SCRIPT_DIR/schema.json"
CONFIG="$BASE/config.json"
USER_CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
ENV_KEY="${OPENAI_API_KEY:-}"
unset OPENAI_API_KEY CODEX_API_KEY
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.npm-global/bin:$PATH"
mkdir -p "$BASE/api-home"

fail() { echo "error: $*" > "$BASE/status.txt"; echo "[codecheck] error: $*" >> "$BASE/last.log"; exit 1; }

echo running > "$BASE/status.txt"
rm -f "$BASE/out.json" "$BASE/route.txt"
: > "$BASE/last.log"

command -v codex >/dev/null || fail "Codex CLI not found - install with: npm install -g @openai/codex"
[ -s "$BASE/prompt.md" ] || fail "no task found ($BASE/prompt.md is missing or empty)"
[ -f "$SCHEMA" ] || fail "schema.json not found next to codex-run.sh"
[ -d "$WORKDIR" ] || fail "workdir does not exist: $WORKDIR"

MODEL="${CODEX_CODECHECK_MODEL:-$(python3 -c "import json,os;p='$CONFIG';print(json.load(open(p)).get('model','gpt-5.6-sol') if os.path.exists(p) else 'gpt-5.6-sol')" 2>/dev/null || echo gpt-5.6-sol)}"
case "$MODE" in
  mini)                    EFFORT=low ;;
  multi|security|optimize) EFFORT=high ;;
  review|consult)          EFFORT=medium ;;
  *)                       fail "unknown mode '$MODE' (review|multi|security|optimize|mini|consult)" ;;
esac

LIMIT_RE='usage.?limit|rate.?limit|limit reached|quota|429|402|billing|insufficient|try again (in|at)|not supported when using|not logged in|unauthori[sz]ed|401|refresh.?token|token.*expired|sign in again'

run_codex() {  # $1 = log file; auth comes from the caller's environment
  codex exec \
      --ignore-user-config --ephemeral --skip-git-repo-check \
      -s read-only -C "$WORKDIR" \
      -m "$MODEL" -c model_reasoning_effort="$EFFORT" \
      --output-schema "$SCHEMA" \
      -o "$BASE/out.json" \
      - < "$BASE/prompt.md" > "$1" 2>&1
}

finish_ok() {  # $1 = route, $2 = start time
  echo "$1" > "$BASE/route.txt"
  echo "[codecheck] route=$1 ok in $(( $(date +%s)-$2 ))s | model=$MODEL | effort=$EFFORT | mode=$MODE" >> "$BASE/last.log"
  echo done > "$BASE/status.txt"; exit 0
}

LOGIN_STATUS="$(CODEX_HOME="$USER_CODEX_HOME" codex login status 2>&1 || true)"

# ---------- 1. ChatGPT account ----------
if [ "${CODEX_CODECHECK_API_ONLY:-0}" != "1" ]; then
  if echo "$LOGIN_STATUS" | grep -qi 'chatgpt'; then
    T0=$(date +%s)
    echo "[codecheck] step 1: ChatGPT account" >> "$BASE/last.log"
    CODEX_HOME="$USER_CODEX_HOME" run_codex "$BASE/last.step1.log"
    RC=$?
    cat "$BASE/last.step1.log" >> "$BASE/last.log"
    if [ $RC -eq 0 ] && [ -s "$BASE/out.json" ]; then finish_ok chatgpt "$T0"; fi
    grep -qiE "$LIMIT_RE" "$BASE/last.step1.log" \
      || fail "exit $RC via ChatGPT account (not a limit/login error, so no API fallback) - see last.log"
    echo "[codecheck] ChatGPT account unavailable ($(grep -oiE "$LIMIT_RE" "$BASE/last.step1.log" | head -1)) -> API key" >> "$BASE/last.log"
    rm -f "$BASE/out.json"
  else
    echo "[codecheck] no ChatGPT login in $USER_CODEX_HOME -> API key" >> "$BASE/last.log"
  fi
fi

[ "${CODEX_CODECHECK_NO_API:-0}" = "1" ] && fail "ChatGPT account unavailable and API fallback disabled (CODEX_CODECHECK_NO_API=1)"

# ---------- 2. OpenAI API key (billed per token) ----------
keyinfo() {  # $1 = index or n, $2 = key|label
  CCK_ENV_KEY="$ENV_KEY" python3 - "$CONFIG" "$1" "${2:-key}" <<'PY'
import json, os, sys
path, idx, field = sys.argv[1], sys.argv[2], sys.argv[3]
keys = []
if os.path.exists(path):
    c = json.load(open(path))
    for i, k in enumerate(c.get("openai_api_keys") or []):
        keys.append((k["key"], k.get("label", f"key{i+1}")) if isinstance(k, dict) else (k, f"key{i+1}"))
    if c.get("openai_api_key"):
        keys.append((c["openai_api_key"], "config"))
if os.environ.get("CCK_ENV_KEY"):
    keys.append((os.environ["CCK_ENV_KEY"], "env"))
if idx == "n":
    print(len(keys))
else:
    print(keys[int(idx)][0 if field == "key" else 1])
PY
}

NKEYS=$(keyinfo n)
if [ "$NKEYS" -eq 0 ]; then
  if echo "$LOGIN_STATUS" | grep -qi 'api key'; then
    T0=$(date +%s)
    echo "[codecheck] step 2: API key from codex login" >> "$BASE/last.log"
    CODEX_HOME="$USER_CODEX_HOME" run_codex "$BASE/last.step2.log"
    RC=$?
    cat "$BASE/last.step2.log" >> "$BASE/last.log"
    if [ $RC -eq 0 ] && [ -s "$BASE/out.json" ]; then finish_ok api:codex-login "$T0"; fi
    fail "exit $RC via API key from codex login - see last.log"
  fi
  fail "no ChatGPT login and no API key - run /codex:setup"
fi

for ((i=0; i<NKEYS; i++)); do
  KEY=$(keyinfo "$i" key); LABEL=$(keyinfo "$i" label)
  T0=$(date +%s)
  echo "[codecheck] step 2: API key '$LABEL'" >> "$BASE/last.log"
  CODEX_HOME="$BASE/api-home" CODEX_API_KEY="$KEY" run_codex "$BASE/last.step2.log"
  RC=$?
  unset KEY
  cat "$BASE/last.step2.log" >> "$BASE/last.log"
  if [ $RC -eq 0 ] && [ -s "$BASE/out.json" ]; then finish_ok "api:$LABEL" "$T0"; fi
  if grep -qiE 'quota|429|402|billing|insufficient' "$BASE/last.step2.log"; then
    echo "[codecheck] key '$LABEL' out of quota -> next key" >> "$BASE/last.log"; continue
  fi
  fail "exit $RC via API key '$LABEL' - see last.log"
done
fail "ChatGPT account and all API keys failed - see last.log"
