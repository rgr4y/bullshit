#!/usr/bin/env bash
# bullshit send.sh — main orchestrator
# Called by agent with: bash send.sh <session_id> [context_messages]
# Designed for run_in_background — stdout IS the delivery mechanism.
# When this script completes, Claude is automatically notified with output.

set -euo pipefail

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly CONFIG_FILE="${HOME}/.config/bullshit/config.json"
readonly PROJECTS_DIR="${HOME}/.claude/projects"
readonly TMP_PREFIX="${TMPDIR:-/tmp}/bullshit"
readonly DEFAULT_CLI="codex"
readonly DEFAULT_CONTEXT_MESSAGES=10
readonly DEFAULT_MAX_CHARS=50000
readonly DEFAULT_TIMEOUT=300
readonly NOTIFY_TITLE="bullshit"

cfg() { python3 -c "import json; print(json.load(open('${CONFIG_FILE}')).get('$1', '$2'))"; }

# --- Session ID (optional — auto-detects from most recent JSONL if omitted) ---
SESSION_ID="${1:-}"

if [[ -z "$SESSION_ID" ]]; then
    echo "No session ID provided, auto-detecting..." >&2
    # Find most recently modified JSONL across all projects
    JSONL_FILE=""
    while IFS= read -r f; do
        JSONL_FILE="$f"
        break
    done < <(find "${PROJECTS_DIR}" -name "*.jsonl" -maxdepth 3 -type f 2>/dev/null | xargs ls -t 2>/dev/null)

    if [[ -z "$JSONL_FILE" || ! -f "$JSONL_FILE" ]]; then
        echo "ERROR: No JSONL session files found in ${PROJECTS_DIR}/" >&2
        echo "Make sure you're running this from an active Claude Code session." >&2
        exit 1
    fi
    SESSION_ID=$(basename "$JSONL_FILE" .jsonl)
    echo "Detected session: ${SESSION_ID}" >&2
    echo "File: ${JSONL_FILE}" >&2
else
    JSONL_FILE=$(find "${PROJECTS_DIR}" -name "${SESSION_ID}.jsonl" -maxdepth 3 -type f 2>/dev/null | head -1)
    if [[ -z "$JSONL_FILE" ]]; then
        echo "ERROR: No JSONL for session ${SESSION_ID}" >&2
        exit 1
    fi
fi

# --- Config (create default if missing) ---
if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<CONF
{
  "preferred_cli": "${DEFAULT_CLI}",
  "context_messages": ${DEFAULT_CONTEXT_MESSAGES},
  "max_chars": ${DEFAULT_MAX_CHARS},
  "timeout_seconds": ${DEFAULT_TIMEOUT}
}
CONF
fi

PREFERRED_CLI=$(cfg preferred_cli "${DEFAULT_CLI}")
CONTEXT_MESSAGES="${2:-$(cfg context_messages "${DEFAULT_CONTEXT_MESSAGES}")}"
MAX_CHARS=$(cfg max_chars "${DEFAULT_MAX_CHARS}")

# --- Check CLI available ---
AVAILABLE=$("${SCRIPT_DIR}/detect-clis.sh" 2>/dev/null || echo '{"available":{}}')
if ! echo "$AVAILABLE" | python3 -c "import sys,json; d=json.load(sys.stdin); assert '${PREFERRED_CLI}' in d['available']" 2>/dev/null; then
    AVAIL_LIST=$(echo "$AVAILABLE" | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin)['available'].keys()))" 2>/dev/null || echo "none")
    echo "ERROR: ${PREFERRED_CLI} not available. Available: ${AVAIL_LIST}" >&2
    exit 1
fi

# --- Extract context ---
CONTEXT=$(python3 "${SCRIPT_DIR}/extract-context.py" "$JSONL_FILE" \
    --messages "$CONTEXT_MESSAGES" \
    --max-chars "$MAX_CHARS")

if [[ -z "$CONTEXT" ]]; then
    echo "ERROR: No conversation context extracted" >&2
    exit 1
fi

# --- Build prompt ---
TIMESTAMP=$(date +%s)
PROMPT_FILE=$(mktemp "${TMP_PREFIX}-prompt.XXXXXX")
OUTPUT_FILE=$(mktemp "${TMP_PREFIX}-raw.XXXXXX")
RESULT_FILE="${TMP_PREFIX}-${PREFERRED_CLI}-${TIMESTAMP}.json"

trap 'rm -f "$PROMPT_FILE" "$OUTPUT_FILE"' EXIT

cat > "$PROMPT_FILE" <<PROMPT
You are a fact-checker and technical reviewer. Another AI assistant (Claude) has been having a conversation with a user. Your job is to review the assistant's claims and identify anything that is:

1. **Factually incorrect** — wrong facts, outdated information, hallucinated APIs/functions/flags
2. **Misleading** — technically true but likely to cause confusion or wrong decisions
3. **Unsupported** — claims presented as fact without basis
4. **Outdated** — was true but no longer accurate

Be specific. Quote the claim, explain what's wrong, and provide the correct information if you know it. If everything checks out, say so — don't manufacture issues.

Focus on technical claims (APIs, commands, library behavior, system behavior). Skip style/opinion.

---
CONVERSATION TO REVIEW:
---

${CONTEXT}

---
END OF CONVERSATION

Provide your review as structured findings. For each issue:
- **Claim**: (quote the problematic statement)
- **Problem**: (what's wrong)
- **Correction**: (what's actually true, if known)
- **Confidence**: (high/medium/low)

If no issues found, say "No significant issues found" and briefly note what was checked.
PROMPT

# --- Invoke adapter ---
ADAPTER="${SCRIPT_DIR}/adapters/${PREFERRED_CLI}.sh"
if [[ ! -x "$ADAPTER" ]]; then
    echo "ERROR: No adapter for ${PREFERRED_CLI}" >&2
    exit 1
fi

START_TIME=$(date +%s)

if ! "$ADAPTER" "$PROMPT_FILE" "$OUTPUT_FILE"; then
    echo "ERROR: ${PREFERRED_CLI} adapter failed" >&2
    terminal-notifier -title "${NOTIFY_TITLE}" -subtitle "${PREFERRED_CLI} failed" -message "Adapter error" -sound Basso 2>/dev/null || true
    exit 1
fi

DURATION=$(( $(date +%s) - START_TIME ))

# --- Write result file (archival) ---
python3 -c "
import json
result = {
    'cli': '${PREFERRED_CLI}',
    'session_id': '${SESSION_ID}',
    'timestamp': '$(date -u +"%Y-%m-%dT%H:%M:%SZ")',
    'status': 'ok',
    'response': open('${OUTPUT_FILE}').read(),
    'duration_seconds': ${DURATION},
    'context_messages': ${CONTEXT_MESSAGES}
}
json.dump(result, open('${RESULT_FILE}', 'w'), indent=2)
"

# --- Deliver via stdout (this is what Claude sees) ---
echo ""
echo "=== BULLSHIT CHECK (${PREFERRED_CLI}, ${DURATION}s, ${CONTEXT_MESSAGES} messages reviewed) ==="
echo ""
cat "$OUTPUT_FILE"
echo ""
echo "=== END BULLSHIT CHECK ==="
echo ""
echo "Result also saved: ${RESULT_FILE}"

# --- Notify (fallback for idle sessions) ---
terminal-notifier -title "${NOTIFY_TITLE}" -subtitle "${PREFERRED_CLI} review ready" -message "Check your Claude session" -sound Glass 2>/dev/null || true
