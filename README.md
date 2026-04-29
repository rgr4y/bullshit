# skill-bullshit

Get a second opinion from another LLM on what your AI assistant just told you.

Dispatches your conversation to codex, gemini, or aider for independent fact-checking. Results delivered back automatically via background task.

## Install

```bash
npx skills add rgr4y/bullshit
```

Or global:

```bash
npx skills add rgr4y/bullshit -g
```

### Manual

```bash
git clone https://github.com/rgr4y/bullshit.git
cd skill-bullshit
bash install.sh
```

## Requirements

At least one of: [`codex`](https://github.com/openai/codex), [`gemini`](https://github.com/google-gemini/gemini-cli), [`aider`](https://github.com/paul-gauthier/aider)

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
4. Sends conversation to codex/gemini/aider with a fact-checking prompt
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

## License

MIT
