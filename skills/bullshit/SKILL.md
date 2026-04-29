---
name: bullshit
aliases:
  - "bs"
description: Use when user invokes /bullshit or /bs — dispatches another LLM CLI (codex, copilot, gemini, aider) to fact-check current session claims. Subcommands: setup, sync, read.
---

# bullshit — Cross-LLM Fact Checker

Dispatches your conversation to another LLM (codex, copilot, gemini, aider) for independent fact-checking.

## Paths

All scripts live in `scripts/` relative to this skill's base directory.
Use the base directory shown when this skill loaded to construct absolute paths.
In commands below, `<base>` = that directory.

## Commands

| Command | Action |
|---------|--------|
| `/bullshit` | Dispatch fact-check to preferred CLI |
| `/bullshit setup` | Configure preferred CLI and options |
| `/bullshit sync` | Re-scan available CLIs (bust 24hr cache) |
| `/bullshit read` | Manually read latest result (fallback) |

## Dispatch (default)

Run send.sh in background. The session ID for this session is: ${CLAUDE_SESSION_ID}

```bash
bash "<base>/scripts/send.sh" ${CLAUDE_SESSION_ID} [N]
```

Second arg = number of conversation messages to review (default: 10). This counts user/assistant turns only — tool calls are excluded. Use more for thorough checks, fewer for quick ones.

Run this with `run_in_background: true`. Tell user: "Dispatched to {cli}. I'll get the results when it's done — keep working."

When background task completes, you receive the fact-check output. Present findings. Think critically — the other LLM can be wrong too. Verify before accepting or dismissing.

## Setup

Run `bash "<base>/scripts/detect-clis.sh"` to show available CLIs. Ask user to pick preferred CLI and context size. Write to `~/.config/bullshit/config.json`:

```json
{"preferred_cli": "codex", "context_messages": 10, "max_chars": 50000, "timeout_seconds": 300}
```

## Sync

```bash
bash "<base>/scripts/detect-clis.sh" --bust-cache
```

## Read (fallback)

Only if background delivery failed. Find latest: `ls -t /tmp/bullshit-*.json | head -1`
