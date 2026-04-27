#!/usr/bin/env bash
# Codex adapter — uses -o flag for clean output, no preamble parsing needed.
#
# Usage: codex.sh <prompt_file> <output_file>

set -euo pipefail

PROMPT_FILE="$1"
OUTPUT_FILE="$2"

PROMPT=$(cat "$PROMPT_FILE")

CONFIG_FILE="${HOME}/.config/bullshit/config.json"
MODEL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('codex_model', 'gpt-5.4'))" 2>/dev/null || echo "gpt-5.4")

timeout 300 codex exec \
    -c 'sandbox_permissions=[]' \
    -c "model=\"${MODEL}\"" \
    --skip-git-repo-check \
    -o "$OUTPUT_FILE" \
    -- "$PROMPT" \
    >/dev/null 2>&1

exit $?
