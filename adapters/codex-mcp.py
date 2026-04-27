#!/usr/bin/env python3
"""Invoke codex via its MCP server (JSON-RPC over stdio).

Usage: codex-mcp.py <prompt_file> <output_file>

Based on the pattern from claude-codex/src/codex.ts.
"""

import json
import subprocess
import sys
import threading
import time

TIMEOUT_SECONDS = 300


def main():
    if len(sys.argv) < 3:
        print("Usage: codex-mcp.py <prompt_file> <output_file>", file=sys.stderr)
        sys.exit(1)

    prompt_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(prompt_file) as f:
        prompt = f.read()

    proc = subprocess.Popen(
        ["codex", "mcp-server"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    responses = {}
    buffer = ""
    lock = threading.Lock()

    def read_stdout():
        nonlocal buffer
        while True:
            chunk = proc.stdout.read(4096)
            if not chunk:
                break
            buffer += chunk.decode("utf-8", errors="replace")
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                line = line.strip()
                if not line:
                    continue
                try:
                    msg = json.loads(line)
                    msg_id = msg.get("id")
                    if msg_id is not None:
                        with lock:
                            responses[msg_id] = msg
                except json.JSONDecodeError:
                    pass

    reader = threading.Thread(target=read_stdout, daemon=True)
    reader.start()

    def send_rpc(msg):
        line = json.dumps(msg) + "\n"
        proc.stdin.write(line.encode())
        proc.stdin.flush()

    def wait_for(msg_id, timeout=30):
        deadline = time.time() + timeout
        while time.time() < deadline:
            with lock:
                if msg_id in responses:
                    return responses.pop(msg_id)
            time.sleep(0.05)
        raise TimeoutError(f"No response for id={msg_id} within {timeout}s")

    try:
        # Initialize
        send_rpc({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "bullshit-checker", "version": "1.0"},
            },
        })
        wait_for(1, timeout=10)

        send_rpc({"jsonrpc": "2.0", "method": "notifications/initialized"})

        # Call codex tool
        send_rpc({
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "codex",
                "arguments": {
                    "prompt": prompt,
                    "model": "o3",
                    "sandbox": "read-only",
                },
            },
        })

        response = wait_for(2, timeout=TIMEOUT_SECONDS)

        if response.get("error"):
            print(f"MCP error: {response['error'].get('message', 'unknown')}", file=sys.stderr)
            sys.exit(1)

        content = response.get("result", {}).get("content", [])
        output = "".join(c.get("text", "") for c in content).strip()

        with open(output_file, "w") as f:
            f.write(output)

    finally:
        proc.terminate()
        proc.wait(timeout=5)


if __name__ == "__main__":
    main()
