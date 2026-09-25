#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)

for tool in molt jq python3; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf '%s is required\n' "$tool" >&2
    exit 1
  }
done

installed=$(molt harness --json | jq -r '.[] | select(.installed != null) | .agent')
for agent in claude codex opencode; do
  if ! printf '%s\n' "$installed" | grep -Fqx "$agent"; then
    printf '%s is not installed; refusing an incomplete snapshot\n' "$agent" >&2
    exit 1
  fi
done

mkdir -p "$REPO/config/harnesses/codex" "$REPO/config/harnesses/opencode"
install -m 0644 "$HOME/.codex/AGENTS.md" "$REPO/config/harnesses/codex/AGENTS.md"
install -m 0644 "$HOME/.config/opencode/AGENTS.md" "$REPO/config/harnesses/opencode/AGENTS.md"

python3 - "$HOME/.codex/config.toml" "$REPO/config/harnesses/codex/config.toml" <<'PY'
import json
import sys
import tomllib
from pathlib import Path

source = tomllib.loads(Path(sys.argv[1]).read_text())
keys = ("model", "model_reasoning_effort", "personality", "service_tier")
lines = []
for key in keys:
    value = source.get(key)
    if isinstance(value, str):
        lines.append(f"{key} = {json.dumps(value)}")
Path(sys.argv[2]).write_text("\n".join(lines) + "\n")
PY

printf 'Exported Claude via config/claude, Codex and OpenCode via config/harnesses.\n'
printf 'Review the diff before committing. Memories, sessions, MCP state and credentials were not copied.\n'
