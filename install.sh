#!/usr/bin/env bash
# bullshit skill installer
# Usage: bash install.sh
#
# Copies skill files to ~/.claude/skills/bullshit/ and ~/.claude/skills/bs/
# Detects available LLM CLIs and creates default config.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${HOME}/.claude/skills/bullshit"
ALIAS_DIR="${HOME}/.claude/skills/bs"
CONFIG_FILE="${HOME}/.config/bullshit/config.json"

echo "Installing bullshit skill..."

# Copy skill files
mkdir -p "$SKILL_DIR/adapters" "$ALIAS_DIR"

cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR/send.sh" "$SKILL_DIR/send.sh"
cp "$SCRIPT_DIR/detect-clis.sh" "$SKILL_DIR/detect-clis.sh"
cp "$SCRIPT_DIR/extract-context.py" "$SKILL_DIR/extract-context.py"
cp "$SCRIPT_DIR/adapters/"*.sh "$SKILL_DIR/adapters/"
cp "$SCRIPT_DIR/adapters/"*.py "$SKILL_DIR/adapters/" 2>/dev/null || true
cp "$SCRIPT_DIR/bs/SKILL.md" "$ALIAS_DIR/SKILL.md"

chmod +x "$SKILL_DIR/send.sh" "$SKILL_DIR/detect-clis.sh" "$SKILL_DIR/extract-context.py" "$SKILL_DIR/adapters/"*

echo "Skill files installed to $SKILL_DIR"

# Detect available CLIs
echo ""
echo "Detecting LLM CLIs..."
AVAILABLE=$("$SKILL_DIR/detect-clis.sh" --bust-cache 2>/dev/null || echo '{"available":{}}')
echo "$AVAILABLE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
clis = d.get('available', {})
if not clis:
    print('  No LLM CLIs found. Install codex, gemini, or aider.')
else:
    for name, info in clis.items():
        print(f'  {name}: {info.get(\"version\", \"unknown\")} ({info.get(\"path\", \"?\")})')
"

# Create default config if missing
if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    # Pick first available CLI as default
    DEFAULT_CLI=$(echo "$AVAILABLE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
clis = list(d.get('available', {}).keys())
# Prefer codex > gemini > aider
for pref in ['codex', 'gemini', 'aider']:
    if pref in clis:
        print(pref)
        break
else:
    print(clis[0] if clis else 'codex')
" 2>/dev/null || echo "codex")
    cat > "$CONFIG_FILE" <<CONF
{
  "preferred_cli": "${DEFAULT_CLI}",
  "context_messages": 50,
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
