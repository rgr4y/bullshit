#!/usr/bin/env bash
# Detect available LLM CLIs and cache results for 24 hours.
# Usage: detect-clis.sh [--bust-cache]
#
# Output: JSON with available CLIs to stdout
# Cache: ~/.cache/bullshit/available-clis.json

set -euo pipefail

CACHE_DIR="${HOME}/.cache/bullshit"
CACHE_FILE="${CACHE_DIR}/available-clis.json"
CACHE_TTL=86400  # 24 hours

mkdir -p "$CACHE_DIR"

# Bust cache if requested
if [[ "${1:-}" == "--bust-cache" ]]; then
    rm -f "$CACHE_FILE"
fi

# Check if cache is fresh
if [[ -f "$CACHE_FILE" ]]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    if (( cache_age < CACHE_TTL )); then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Probe each CLI
declare -A CLI_CMDS=(
    ["codex"]="codex exec"
    ["gemini"]="gemini -p"
    ["aider"]="aider --message"
)

available='{'
first=true

for cli in codex gemini aider; do
    cli_path=$(which "$cli" 2>/dev/null || true)
    if [[ -z "$cli_path" ]]; then
        continue
    fi

    # Get version (best effort)
    version=""
    case "$cli" in
        codex)  version=$(codex --version 2>/dev/null | head -1 || echo "unknown") ;;
        gemini) version=$(gemini --version 2>/dev/null | head -1 || echo "unknown") ;;
        aider)  version=$(aider --version 2>/dev/null | head -1 || echo "unknown") ;;
    esac

    if [[ "$first" != true ]]; then
        available+=','
    fi
    first=false

    # JSON-escape values
    cli_path_escaped=$(printf '%s' "$cli_path" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()), end="")')
    version_escaped=$(printf '%s' "$version" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()), end="")')

    available+="\"$cli\":{\"path\":${cli_path_escaped},\"version\":${version_escaped},\"invoke\":\"${CLI_CMDS[$cli]}\"}"
done

available+='}'

# Wrap with metadata
now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
result="{\"timestamp\":\"${now}\",\"available\":${available}}"

echo "$result" | python3 -m json.tool > "$CACHE_FILE"
cat "$CACHE_FILE"
