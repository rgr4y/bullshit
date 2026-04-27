#!/usr/bin/env bash
# Codex adapter — minimal invocation, no plugins/rules/config overhead.
#
# Usage: codex.sh <prompt_file> <output_file>

set -euo pipefail

PROMPT_FILE="$1"
OUTPUT_FILE="$2"

PROMPT=$(cat "$PROMPT_FILE")

CONFIG_FILE="${HOME}/.config/bullshit/config.json"
MODEL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('codex_model', 'gpt-5.4'))" 2>/dev/null || echo "gpt-5.4")

timeout 300 codex exec \
    --ephemeral \
    --ignore-rules \
    --ignore-user-config \
    --dangerously-bypass-approvals-and-sandbox \
    --full-auto \
    -c "model=\"${MODEL}\"" \
    --skip-git-repo-check \
    -o "$OUTPUT_FILE" \
    -- "$PROMPT" \
    >/dev/null 2>&1

exit $?
