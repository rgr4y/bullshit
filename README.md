# bullshit

Get a second opinion from another LLM on what Claude just told you.

Dispatches your conversation to codex, gemini, or aider for fact-checking. Results delivered back automatically via background task.

## Install

```bash
git clone <this-repo> && cd bullshit && bash install.sh
```

Requires at least one of: `codex`, `gemini`, `aider` (or `sgpt`).

## Usage

In Claude Code:

- `/bullshit` — send current session for fact-checking
- `/bullshit setup` — pick which CLI to use
- `/bullshit sync` — re-detect available CLIs
- `/bullshit read` — manually read latest result (fallback)

`/bs` works as alias for all commands.

## How it works

1. You say `/bullshit`
2. Claude runs `send.sh` in background
3. Script reads your session JSONL directly (no agent summary = no bias)
4. Sends conversation to codex/gemini with a fact-checking prompt
5. When done, Claude gets notified automatically and presents findings
6. You keep working the whole time

## Config

`~/.config/bullshit/config.json`:

```json
{
  "preferred_cli": "codex",
  "context_messages": 50,
  "max_chars": 50000,
  "timeout_seconds": 300
}
```
