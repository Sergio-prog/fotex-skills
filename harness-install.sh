#!/bin/sh
set -eu

RAW_BASE=${FOTEX_RAW_BASE:-https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/fotex-harness.XXXXXX")

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

fetch() {
  curl -fsSL "$1" -o "$2"
}

backup_and_install() {
  source_file=$1
  destination=$2
  mkdir -p "$(dirname "$destination")"
  if [ -f "$destination" ] && cmp -s "$source_file" "$destination"; then
    return
  fi
  if [ -e "$destination" ]; then
    cp -p "$destination" "$destination.bak.$TIMESTAMP"
    printf '[fotex] Backed up %s\n' "$destination"
  fi
  install -m 0644 "$source_file" "$destination"
}

install_npm_harness() {
  binary=$1
  package=$2
  if command -v "$binary" >/dev/null 2>&1; then
    printf '[fotex] %s is already installed\n' "$binary"
    return
  fi
  prefix=$HOME/.local/share/fotex/$binary
  npm install --prefix "$prefix" "$package"
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$prefix/node_modules/.bin/$binary" "$HOME/.local/bin/$binary"
}

[ "$(uname -s)" = Linux ] || { printf 'harness-install.sh is intended for Linux hosts\n' >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { printf 'curl is required\n' >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { printf 'npm is required; run claude-install.sh first\n' >&2; exit 1; }

export PATH="$HOME/.local/bin:$PATH"
install_npm_harness codex @openai/codex
install_npm_harness opencode opencode-ai

if ! command -v molt >/dev/null 2>&1; then
  fetch https://raw.githubusercontent.com/Sergio-prog/molt/main/install.sh "$TEMP_DIR/molt-install.sh"
  MOLT_INSTALL_DIR="$HOME/.local/bin" sh "$TEMP_DIR/molt-install.sh"
fi

for relative_path in codex/config.toml codex/AGENTS.md opencode/AGENTS.md; do
  fetch "$RAW_BASE/config/harnesses/$relative_path" "$TEMP_DIR/$(basename "$relative_path")"
  case "$relative_path" in
    codex/*) destination=$HOME/.codex/$(basename "$relative_path") ;;
    opencode/*) destination=$HOME/.config/opencode/$(basename "$relative_path") ;;
  esac
  backup_and_install "$TEMP_DIR/$(basename "$relative_path")" "$destination"
done

printf '[fotex] Codex, OpenCode and molt are ready. Sign in to each CLI on this host.\n'
