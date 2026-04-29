#!/usr/bin/env bash
# Adapter: codex
# Contract: adapters/<name>.sh where <name> matches the CLI binary
#   --probe         → exit 0 + JSON if available, exit 1 if not
#   <prompt> <out>  → run fact-check, write result to <out>

set -euo pipefail

readonly CONFIG_FILE="${HOME}/.config/bullshit/config.json"
readonly DEFAULT_MODEL="gpt-5.4"
readonly TMP_PREFIX="${TMPDIR:-/tmp}/bullshit"

# --- Probe mode ---
if [[ "${1:-}" == "--probe" ]]; then
    BIN=$(command -v codex 2>/dev/null) || exit 1
    VER=$(codex --version 2>/dev/null | head -1 || echo "unknown")
    echo "{\"binary\":\"codex\",\"path\":\"${BIN}\",\"version\":\"${VER}\",\"invoke\":\"codex exec\"}"
    exit 0
fi

# --- Run mode ---
PROMPT_FILE="$1"
OUTPUT_FILE="$2"

PROMPT=$(cat "$PROMPT_FILE")

MODEL=$(python3 -c "import json; print(json.load(open('${CONFIG_FILE}')).get('codex_model', '${DEFAULT_MODEL}'))" 2>/dev/null || echo "${DEFAULT_MODEL}")

INSTRUCTIONS="${TMP_PREFIX}-instructions.txt"
[[ -f "$INSTRUCTIONS" ]] || echo "You are a terse fact-checker. Output only the review." > "$INSTRUCTIONS"

RAW_JSON=$(mktemp "${TMP_PREFIX}-codex-json.XXXXXX")
trap 'rm -f "$RAW_JSON"' EXIT

timeout 300 codex exec \
    --ephemeral \
    --ignore-rules \
    --ignore-user-config \
    --json \
    --skip-git-repo-check \
    -c "model=\"${MODEL}\"" \
    -c "model_instructions_file=\"${INSTRUCTIONS}\"" \
    -c 'project_doc_max_bytes=0' \
    -c 'include_permissions_instructions=false' \
    -c 'include_apps_instructions=false' \
    -c 'skills.include_instructions=false' \
    -c 'include_environment_context=false' \
    -c 'web_search="disabled"' \
    -c 'mcp_servers={}' \
    -c 'skills.bundled.enabled=false' \
    -c 'features.shell_tool=false' \
    -c 'features.apps=false' \
    -c 'features.plugins=false' \
    -c 'features.tool_search=false' \
    -c 'features.codex_hooks=false' \
    -c 'features.multi_agent=false' \
    -- "$PROMPT" \
    > "$RAW_JSON" 2>/dev/null

python3 -c "
import json
texts = []
for line in open('$RAW_JSON'):
    line = line.strip()
    if not line:
        continue
    try:
        event = json.loads(line)
        if event.get('type') == 'item.completed':
            item = event.get('item', {})
            if item.get('type') == 'agent_message':
                text = item.get('text', '').strip()
                if text:
                    texts.append(text)
    except json.JSONDecodeError:
        pass
print('\n\n'.join(texts))
" > "$OUTPUT_FILE"
