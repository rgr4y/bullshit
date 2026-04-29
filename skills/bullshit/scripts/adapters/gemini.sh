#!/usr/bin/env bash
# Gemini adapter — uses `gemini -p` for headless one-shot mode.
#
# Usage: gemini.sh <prompt_file> <output_file>

set -euo pipefail

PROMPT_FILE="$1"
OUTPUT_FILE="$2"

PROMPT=$(cat "$PROMPT_FILE")

timeout 300 gemini -p "$PROMPT" \
  --sandbox \
  > "$OUTPUT_FILE" 2>/dev/null

exit $?
