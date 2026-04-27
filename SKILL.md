---
name: bullshit
description: Use when user invokes /bullshit or /bs — dispatches another LLM CLI (codex, gemini, aider) to fact-check current session claims. Subcommands: setup, sync, read.
---

# bullshit — Cross-LLM Fact Checker

## Install

If `~/.claude/skills/bullshit/send.sh` does not exist, run the installer:

```bash
bash /path/to/this/repo/install.sh
```

The installer copies scripts, detects available CLIs, and creates default config. Follow its output.

## Commands

| Command | Action |
|---------|--------|
| `/bullshit` | Dispatch fact-check to preferred CLI |
| `/bullshit setup` | Configure preferred CLI and options |
| `/bullshit sync` | Re-scan available CLIs (bust 24hr cache) |
| `/bullshit read` | Manually read latest result (fallback) |

## Dispatch (default)

Run send.sh in background with no arguments — it auto-detects the current session from the most recent JSONL file in `~/.claude/projects/`.

```bash
bash ~/.claude/skills/bullshit/send.sh
```

Run this with `run_in_background: true`. Tell user: "Dispatched to {cli}. I'll get the results when it's done — keep working."

When background task completes, you receive the fact-check output. Present findings. Think critically — the other LLM can be wrong too. Verify before accepting or dismissing.

## Setup

Run `bash ~/.claude/skills/bullshit/detect-clis.sh` to show available CLIs. Ask user to pick preferred CLI and context size. Write to `~/.config/bullshit/config.json`:

```json
{"preferred_cli": "codex", "context_messages": 50, "max_chars": 50000, "timeout_seconds": 300}
```

## Sync

```bash
bash ~/.claude/skills/bullshit/detect-clis.sh --bust-cache
```

## Read (fallback)

Only if background delivery failed. Find latest: `ls -t /tmp/bullshit-*.json | head -1`
