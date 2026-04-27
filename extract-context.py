#!/usr/bin/env python3
"""Extract clean conversation text from Claude Code JSONL session files.

Usage: extract-context.py <jsonl_path> [--messages N] [--max-chars N]

Outputs a readable conversation transcript suitable for fact-checking by another LLM.
Skips tool calls, thinking blocks, system messages, and hook attachments.
"""

import json
import sys
import argparse
from pathlib import Path


def extract_text_from_content(content):
    """Extract readable text from message content (string or content blocks array)."""
    if isinstance(content, str):
        # Strip command/system tags for cleaner output
        text = content
        # Remove XML-style system tags but keep the substance
        import re
        text = re.sub(r'<system-reminder>.*?</system-reminder>', '', text, flags=re.DOTALL)
        text = re.sub(r'<local-command-caveat>.*?</local-command-caveat>', '', text, flags=re.DOTALL)
        text = re.sub(r'<local-command-stdout>.*?</local-command-stdout>', '', text, flags=re.DOTALL)
        text = re.sub(r'<command-message>.*?</command-message>', '', text, flags=re.DOTALL)
        text = re.sub(r'<command-name>.*?</command-name>', '', text, flags=re.DOTALL)
        text = re.sub(r'<command-args>.*?</command-args>', '', text, flags=re.DOTALL)
        text = text.strip()
        return text if text else None

    if isinstance(content, list):
        parts = []
        for block in content:
            if not isinstance(block, dict):
                continue
            btype = block.get('type', '')
            if btype == 'text':
                t = block.get('text', '').strip()
                if t:
                    parts.append(t)
            elif btype == 'tool_result':
                # Include tool results as they contain factual claims
                sub = block.get('content', '')
                if isinstance(sub, str) and sub.strip():
                    parts.append(f"[tool output]: {sub.strip()[:500]}")
                elif isinstance(sub, list):
                    for sb in sub:
                        if isinstance(sb, dict) and sb.get('type') == 'text':
                            parts.append(f"[tool output]: {sb.get('text', '').strip()[:500]}")
        return '\n'.join(parts) if parts else None

    return None


def parse_jsonl(path, max_messages=50, max_chars=50000):
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

    # Take last N messages
    messages = messages[-max_messages:]

    # Trim to max chars from the end
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
    parser.add_argument('--messages', type=int, default=50, help='Max messages to extract (default: 50)')
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
