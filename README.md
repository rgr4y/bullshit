# bullshit

Get a second opinion from another LLM on what your AI assistant just told you.

Dispatches your conversation to codex, copilot, gemini, or aider for independent fact-checking. Results delivered back automatically via background task.

## Install

```bash
npx skills add rgr4y/bullshit -g
```

### Manual

```bash
git clone https://github.com/rgr4y/bullshit.git
cd bullshit
bash install.sh
```

## Requirements

At least one of: [`codex`](https://github.com/openai/codex), [`copilot`](https://docs.github.com/copilot/how-tos/copilot-cli), [`gemini`](https://github.com/google-gemini/gemini-cli), [`aider`](https://github.com/paul-gauthier/aider)

## Usage

In Claude Code:

- `/bullshit` — send current session for fact-checking
- `/bullshit setup` — pick which CLI to use
- `/bullshit sync` — re-detect available CLIs
- `/bullshit read` — manually read latest result (fallback)

`/bs` works as alias.

## How it works

1. You say `/bullshit`
2. Script reads your session JSONL directly (no agent summary = no bias)
3. Sends conversation to codex/copilot/gemini/aider with a fact-checking prompt
4. Claude gets notified when done and presents findings
5. You keep working the whole time

## Adding a new adapter

Drop a file in `skills/bullshit/scripts/adapters/<cli_name>.sh`. The filename must match the CLI binary name. Two modes:

```bash
# Probe: exit 0 + JSON if CLI available, exit 1 if not
adapters/mycli.sh --probe
# → {"binary":"mycli","path":"/usr/bin/mycli","version":"1.0","invoke":"mycli run"}

# Run: read prompt from file, write fact-check output to file
adapters/mycli.sh <prompt_file> <output_file>
```

No registration needed — `detect-clis.sh` scans adapters/ automatically.

## Config

`~/.config/bullshit/config.json`:

```json
{
  "preferred_cli": "codex",
  "context_messages": 10,
  "max_chars": 50000,
  "timeout_seconds": 300
}
```

## License

MIT
