#!/usr/bin/env bash
# Codex adapter — absolute minimum footprint, --json output.
#
# Usage: codex.sh <prompt_file> <output_file>

set -euo pipefail

PROMPT_FILE="$1"
OUTPUT_FILE="$2"

PROMPT=$(cat "$PROMPT_FILE")

CONFIG_FILE="${HOME}/.config/bullshit/config.json"
MODEL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('codex_model', 'gpt-5.4'))" 2>/dev/null || echo "gpt-5.4")

# Minimal instructions file (created once)
INSTRUCTIONS="${TMPDIR:-/tmp}/bullshit-instructions.txt"
[[ -f "$INSTRUCTIONS" ]] || echo "You are a terse fact-checker. Output only the review." > "$INSTRUCTIONS"

RAW_JSON=$(mktemp "${TMPDIR:-/tmp}/bullshit-codex-json.XXXXXX")
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
import json, sys
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

exit $?
