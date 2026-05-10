#!/bin/bash
# log-search.sh — append a single jsonl record per WebSearch / WebFetch / gemini-search call.
# Wired up by ../hooks/hooks.json as a PostToolUse hook.
#
# Reads tool input/response JSON from stdin (Claude Code hook contract).
# Writes one compact record to .checkpoint/search-backup.jsonl in the user's CWD.
# The redirect target is intentionally CWD-relative — backups belong with the
# user's research output, not with the plugin install.

set -e

mkdir -p .checkpoint

jq -c '{
  ts: now,
  tool: .tool_name,
  query: (.tool_input.query // .tool_input.url // empty),
  result_length: ((.tool_response | tostring) | length)
}' >> .checkpoint/search-backup.jsonl 2>/dev/null || true
