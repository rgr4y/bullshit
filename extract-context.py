#!/usr/bin/env python3
"""Extract clean conversation text from Claude Code JSONL session files.

Usage: extract-context.py <jsonl_path> [--messages N] [--max-chars N]

Outputs a readable conversation transcript suitable for fact-checking by another LLM.
Tool calls become [Used tool: Name] placeholders. System/thinking/hooks stripped.
"""

import json
import re
import sys
import argparse
from pathlib import Path

# Tags to strip from string content
STRIP_TAGS = re.compile(
    r'<(?:system-reminder|local-command-caveat|local-command-stdout|'
    r'command-message|command-name|command-args|task-notification)>'
    r'.*?'
    r'</(?:system-reminder|local-command-caveat|local-command-stdout|'
    r'command-message|command-name|command-args|task-notification)>',
    re.DOTALL
)


def extract_text_from_content(content):
    """Extract readable text from message content, replacing tool calls with placeholders."""
    if isinstance(content, str):
        text = STRIP_TAGS.sub('', content).strip()
        return text if text else None

    if not isinstance(content, list):
        return None

    parts = []
    for block in content:
        if not isinstance(block, dict):
            continue
        btype = block.get('type', '')

        if btype == 'text':
            t = block.get('text', '').strip()
            if t:
                parts.append(t)

        elif btype == 'tool_use':
            name = block.get('name', '?')
            inp = block.get('input', {})
            # Brief context for key tools
            hint = ''
            if name in ('Read', 'read') and inp.get('file_path'):
                hint = f" {inp['file_path']}"
            elif name in ('Bash', 'bash') and inp.get('command'):
                cmd = inp['command'][:80]
                hint = f" `{cmd}`"
            elif name in ('Edit', 'edit', 'Write', 'write') and inp.get('file_path'):
                hint = f" {inp['file_path']}"
            elif name in ('WebFetch', 'webfetch') and inp.get('url'):
                hint = f" {inp['url']}"
            parts.append(f"[Used tool: {name}{hint}]")

        elif btype == 'tool_result':
            is_error = block.get('is_error', False)
            if is_error:
                sub = block.get('content', '')
                if isinstance(sub, str):
                    parts.append(f"[Tool error: {sub[:200]}]")
                else:
                    parts.append("[Tool error]")
            # Skip successful tool results — the tool_use placeholder is enough

        # Skip: thinking, server_tool_use, mcp results, etc.

    return '\n'.join(parts) if parts else None


def parse_jsonl(path, max_messages=10, max_chars=50000):
    """Parse JSONL and return conversation messages."""
    messages = []

    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg_type = obj.get('type')
            if msg_type not in ('user', 'assistant'):
                continue

            message = obj.get('message', {})
            role = message.get('role', msg_type)
            content = message.get('content')

            if content is None:
                continue

            text = extract_text_from_content(content)
            if not text:
                continue

            messages.append({
                'role': role,
                'text': text
            })

    messages = messages[-max_messages:]

    result = []
    total_chars = 0
    for msg in reversed(messages):
        if total_chars + len(msg['text']) > max_chars:
            remaining = max_chars - total_chars
            if remaining > 200:
                msg['text'] = '...' + msg['text'][-(remaining - 3):]
                result.insert(0, msg)
            break
        total_chars += len(msg['text'])
        result.insert(0, msg)

    return result


def format_conversation(messages):
    """Format messages into readable conversation transcript."""
    lines = []
    for msg in messages:
        role = msg['role'].upper()
        lines.append(f"=== {role} ===")
        lines.append(msg['text'])
        lines.append("")
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description='Extract conversation from Claude JSONL')
    parser.add_argument('jsonl_path', help='Path to JSONL session file')
    parser.add_argument('--messages', type=int, default=10, help='Max messages to extract (default: 10)')
    parser.add_argument('--max-chars', type=int, default=50000, help='Max total characters (default: 50000)')
    parser.add_argument('--json', action='store_true', help='Output as JSON instead of text')
    args = parser.parse_args()

    path = Path(args.jsonl_path)
    if not path.exists():
        print(f"Error: {path} not found", file=sys.stderr)
        sys.exit(1)

    messages = parse_jsonl(path, max_messages=args.messages, max_chars=args.max_chars)

    if not messages:
        print("Error: No conversation messages found", file=sys.stderr)
        sys.exit(1)

    if args.json:
        json.dump(messages, sys.stdout, indent=2)
    else:
        print(format_conversation(messages))


if __name__ == '__main__':
    main()
