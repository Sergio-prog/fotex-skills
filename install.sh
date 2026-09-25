#!/bin/sh
set -eu

RAW_BASE=${FOTEX_RAW_BASE:-https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/fotex-install.XXXXXX")

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

curl -fsSL "$RAW_BASE/ghostty-install.sh" -o "$TEMP_DIR/ghostty-install.sh"
curl -fsSL "$RAW_BASE/claude-install.sh" -o "$TEMP_DIR/claude-install.sh"
curl -fsSL "$RAW_BASE/harness-install.sh" -o "$TEMP_DIR/harness-install.sh"

FOTEX_RAW_BASE=$RAW_BASE sh "$TEMP_DIR/ghostty-install.sh"
FOTEX_RAW_BASE=$RAW_BASE sh "$TEMP_DIR/claude-install.sh"
FOTEX_RAW_BASE=$RAW_BASE sh "$TEMP_DIR/harness-install.sh"
