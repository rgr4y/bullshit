#!/usr/bin/env bash
# Detect available LLM CLIs by probing installed adapters.
# Usage: detect-clis.sh [--bust-cache]
#
# Scans adapters/*.sh, calls each with --probe.
# Output: JSON with available CLIs to stdout
# Cache: ~/.cache/bullshit/available-clis.json

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly ADAPTERS_DIR="${SCRIPT_DIR}/adapters"
readonly CACHE_DIR="${HOME}/.cache/bullshit"
readonly CACHE_FILE="${CACHE_DIR}/available-clis.json"
readonly CACHE_TTL=86400

mkdir -p "$CACHE_DIR"

if [[ "${1:-}" == "--bust-cache" ]]; then
    rm -f "$CACHE_FILE"
fi

if [[ -f "$CACHE_FILE" ]]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    if (( cache_age < CACHE_TTL )); then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Probe each adapter
available='{'
first=true

for adapter in "${ADAPTERS_DIR}"/*.sh; do
    [[ -x "$adapter" ]] || continue

    info=$("$adapter" --probe 2>/dev/null) || continue

    cli_name=$(basename "$adapter" .sh)

    if [[ "$first" != true ]]; then
        available+=','
    fi
    first=false

    available+="\"${cli_name}\":${info}"
done

available+='}'

now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
result="{\"timestamp\":\"${now}\",\"available\":${available}}"

echo "$result" | python3 -m json.tool > "$CACHE_FILE"
cat "$CACHE_FILE"
