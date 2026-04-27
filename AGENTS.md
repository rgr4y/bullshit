<claude-mem-context>
# Memory Context

# [bullshit] recent context, 2026-04-27 5:16am PDT

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 10 obs (2,161t read) | 148,444t work | 99% savings

### Apr 27, 2026
8157 5:10a 🔵 Confirmed arithmetic calculation for 2+2
8159 " 🔵 Confirmed correct calculation of 2+2
8160 5:11a 🔵 Confirmed basic arithmetic query handling
8168 " 🟣 Codex adapter script updated to strip preamble and extract model response
8169 5:12a 🔵 Codex CLI session file permission error blocks execution
8170 " 🔵 Codex MCP adapter hardcodes model to "o3" in JSON-RPC call
**8164** " 🟣 **Asynchronous skill execution via run_in_background for fact-checking agents**
send.sh orchestrator script now runs as a background task using run_in_background
Background completion triggers automatic notification and delivery of output to the Claude session
Manual polling, prompt hooks, and channels are no longer required for message delivery
Skill is compatible with desktop environments without channel support
Minimal SKILL.md and adapter scripts created for codex, gemini, and aider CLIs
~326t

**8165** " 🔴 **Fixed Codex adapter fallback and model selection issues**
codex exec now uses --skip-git-repo-check to run outside git repositories
codex.sh adapter script updated to specify gpt-5.4 as the model to avoid unsupported model errors
Adapter now strips preamble headers from codex output to return only the model response
Fallback logic improved to handle MCP and exec invocation failures gracefully
~285t

8166 " 🔵 Identified model and CLI compatibility constraints for Codex integration
**8174** 5:15a 🔵 **Python lists use dynamic arrays, not linked lists**
Python lists are backed by dynamic arrays in CPython
Linked list implementation would have different time complexities for indexing and insertion
Common claim about Python lists being linked lists is incorrect
~192t


Access 148k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>