#!/usr/bin/env bash
# Manual installer for bullshit skill
# Preferred: npx skills add rgr4y/bullshit -g
#
# Usage: bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${HOME}/.claude/skills/bullshit"
CONFIG_FILE="${HOME}/.config/bullshit/config.json"

echo "Installing bullshit skill..."

# Copy skill + scripts
mkdir -p "$SKILL_DIR/scripts/adapters"

cp "$SCRIPT_DIR/skills/bullshit/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR/skills/bullshit/scripts/"*.sh "$SKILL_DIR/scripts/"
cp "$SCRIPT_DIR/skills/bullshit/scripts/"*.py "$SKILL_DIR/scripts/"
cp "$SCRIPT_DIR/skills/bullshit/scripts/adapters/"* "$SKILL_DIR/scripts/adapters/"

chmod +x "$SKILL_DIR/scripts/"*.sh "$SKILL_DIR/scripts/"*.py "$SKILL_DIR/scripts/adapters/"*

echo "Skill files installed to $SKILL_DIR"

# Detect available CLIs
echo ""
echo "Detecting LLM CLIs..."
AVAILABLE=$("$SKILL_DIR/scripts/detect-clis.sh" --bust-cache 2>/dev/null || echo '{"available":{}}')
echo "$AVAILABLE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
clis = d.get('available', {})
if not clis:
    print('  No LLM CLIs found. Drop an adapter in scripts/adapters/ or install codex/copilot/gemini/aider.')
else:
    for name, info in clis.items():
        print(f'  {name}: {info.get(\"version\", \"unknown\")} ({info.get(\"path\", \"?\")})')
"

# Create default config if missing
if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    DEFAULT_CLI=$(echo "$AVAILABLE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
clis = list(d.get('available', {}).keys())
print(clis[0] if clis else 'codex')
" 2>/dev/null || echo "codex")
    cat > "$CONFIG_FILE" <<CONF
{
  "preferred_cli": "${DEFAULT_CLI}",
  "context_messages": 10,
  "max_chars": 50000,
  "timeout_seconds": 300
}
CONF
    echo ""
    echo "Config created: $CONFIG_FILE (default: ${DEFAULT_CLI})"
else
    echo ""
    echo "Config exists: $CONFIG_FILE"
fi

echo ""
echo "Done. Use /bullshit or /bs in Claude Code."
echo "Run /bullshit setup to change preferred CLI."
