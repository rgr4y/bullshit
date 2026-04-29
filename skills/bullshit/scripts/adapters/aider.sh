#!/usr/bin/env bash
# Aider adapter — uses aider --message for one-shot mode.
# Note: aider is a coding assistant, not ideal for fact-checking.
# Works in a temp dir to avoid touching real files.
#
# Usage: aider.sh <prompt_file> <output_file>

set -euo pipefail

PROMPT_FILE="$1"
OUTPUT_FILE="$2"

PROMPT=$(cat "$PROMPT_FILE")

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
git init -q

timeout 300 aider \
  --message "$PROMPT" \
  --no-auto-commits \
  --no-git \
  --yes \
  2>/dev/null \
  | grep -v '^>' \
  > "$OUTPUT_FILE"

exit $?
