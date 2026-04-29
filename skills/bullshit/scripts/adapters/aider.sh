#!/usr/bin/env bash
# Adapter: aider
# Contract: adapters/<name>.sh where <name> matches the CLI binary
#   --probe         → exit 0 + JSON if available, exit 1 if not
#   <prompt> <out>  → run fact-check, write result to <out>

set -euo pipefail

# --- Probe mode ---
if [[ "${1:-}" == "--probe" ]]; then
    BIN=$(command -v aider 2>/dev/null) || exit 1
    VER=$(aider --version 2>/dev/null | head -1 || echo "unknown")
    echo "{\"binary\":\"aider\",\"path\":\"${BIN}\",\"version\":\"${VER}\",\"invoke\":\"aider --message\"}"
    exit 0
fi

# --- Run mode ---
PROMPT_FILE="$1"
OUTPUT_FILE="$2"

PROMPT=$(cat "$PROMPT_FILE")

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bullshit-aider.XXXXXX")
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$WORK_DIR"
git init -q

timeout 300 aider \
    --message "$PROMPT" \
    --no-auto-commits \
    --no-git \
    --yes \
    2>/dev/null \
    | grep -v '^>' \
    > "$OUTPUT_FILE"
