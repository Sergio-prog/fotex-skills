#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/fotex-export.XXXXXX")

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

require_file() {
  if [[ ! -f $1 ]]; then
    printf 'missing required file: %s\n' "$1" >&2
    exit 1
  fi
}

copy_file() {
  local source=$1
  local destination=$2
  require_file "$source"
  mkdir -p "$(dirname "$destination")"
  cp "$source" "$destination"
  printf 'updated %s\n' "${destination#"$REPO"/}"
}

command -v jq >/dev/null 2>&1 || {
  printf 'jq is required\n' >&2
  exit 1
}
command -v rsync >/dev/null 2>&1 || {
  printf 'rsync is required\n' >&2
  exit 1
}

copy_file "$HOME/.config/micro/bindings.json" "$REPO/config/micro/bindings.json"
copy_file "$HOME/.config/micro/init.lua" "$REPO/config/micro/init.lua"
require_file "$HOME/.config/micro/settings.json"
jq '. + {clipboard: "terminal", useprimary: false, keymenu: false}' \
  "$HOME/.config/micro/settings.json" >"$TEMP_DIR/micro-settings.json"
mv "$TEMP_DIR/micro-settings.json" "$REPO/config/micro/settings.json"
printf 'updated config/micro/settings.json\n'

mkdir -p "$REPO/config/ghostty"
if infocmp -x xterm-ghostty >"$TEMP_DIR/xterm-ghostty.terminfo" 2>/dev/null; then
  :
elif [[ -f /Applications/cmux.app/Contents/Resources/terminfo/78/xterm-ghostty ]]; then
  TERMINFO=/Applications/cmux.app/Contents/Resources/terminfo \
    infocmp -x xterm-ghostty >"$TEMP_DIR/xterm-ghostty.terminfo"
elif [[ -f /Applications/Ghostty.app/Contents/Resources/terminfo/78/xterm-ghostty ]]; then
  TERMINFO=/Applications/Ghostty.app/Contents/Resources/terminfo \
    infocmp -x xterm-ghostty >"$TEMP_DIR/xterm-ghostty.terminfo"
else
  printf 'could not find xterm-ghostty terminfo\n' >&2
  exit 1
fi
{
  printf '# xterm-ghostty terminfo exported from cmux\n'
  sed '1d' "$TEMP_DIR/xterm-ghostty.terminfo"
} >"$TEMP_DIR/xterm-ghostty.normalized.terminfo"
mv "$TEMP_DIR/xterm-ghostty.normalized.terminfo" "$REPO/config/ghostty/xterm-ghostty.terminfo"
printf 'updated config/ghostty/xterm-ghostty.terminfo\n'

copy_file "$HOME/.claude/CLAUDE.md" "$REPO/config/claude/CLAUDE.md"
require_file "$HOME/.claude/settings.json"
jq '{
  attribution,
  includeCoAuthoredBy,
  permissions: {
    defaultMode: .permissions.defaultMode
  },
  model,
  enabledPlugins: {
    "fotex-skills@fotex": true,
    "mattpocock-skills@claude-plugins-official": true
  },
  effortLevel,
  awaySummaryEnabled,
  voice,
  autoCompactEnabled,
  remoteControlAtStartup,
  voiceEnabled
}' "$HOME/.claude/settings.json" >"$TEMP_DIR/claude-settings.json"
mv "$TEMP_DIR/claude-settings.json" "$REPO/config/claude/settings.json"
printf 'updated config/claude/settings.json\n'

while IFS= read -r skill_name; do
  [[ -z $skill_name || $skill_name == \#* ]] && continue
  source_dir=$HOME/.agents/skills/$skill_name
  if [[ ! -f $source_dir/SKILL.md ]]; then
    printf 'missing skill: %s\n' "$source_dir" >&2
    exit 1
  fi
  mkdir -p "$REPO/skills/$skill_name"
  rsync -a --delete \
    --exclude .git \
    --exclude node_modules \
    --exclude scripts/.impeccable \
    "$source_dir/" "$REPO/skills/$skill_name/"
  printf 'updated skills/%s\n' "$skill_name"
done <"$REPO/config/claude/export-skills.txt"

jq empty "$REPO/config/micro/settings.json" "$REPO/config/micro/bindings.json" "$REPO/config/claude/settings.json"
"$REPO/scripts/export-harnesses.sh"
printf 'workflow snapshot updated at %s\n' "$TIMESTAMP"
