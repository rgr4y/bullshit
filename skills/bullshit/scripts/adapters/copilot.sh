#!/usr/bin/env bash
# Adapter: copilot (GitHub Copilot CLI)
# Contract: adapters/<name>.sh where <name> matches the CLI binary
#   --probe         → exit 0 + JSON if available, exit 1 if not
#   <prompt> <out>  → run fact-check, write result to <out>

set -euo pipefail

# --- Probe mode ---
if [[ "${1:-}" == "--probe" ]]; then
    BIN=$(command -v copilot 2>/dev/null) || exit 1
    VER=$(copilot --version 2>/dev/null | head -1 || echo "unknown")
    echo "{\"binary\":\"copilot\",\"path\":\"${BIN}\",\"version\":\"${VER}\",\"invoke\":\"copilot -p\"}"
    exit 0
fi

# --- Run mode ---
PROMPT_FILE="$1"
OUTPUT_FILE="$2"

PROMPT=$(cat "$PROMPT_FILE")

timeout 300 copilot -p "$PROMPT" \
    --silent \
    --no-custom-instructions \
    --allow-all-tools \
    --no-remote \
    > "$OUTPUT_FILE" 2>/dev/null
