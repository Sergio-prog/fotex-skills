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

codex=0 opencode=0 molt=0
if [ "$#" -eq 0 ]; then
  codex=1 opencode=1 molt=1
fi
for option do
  case "$option" in
    --codex) codex=1 ;;
    --opencode) opencode=1 ;;
    --molt) molt=1 ;;
    *) printf 'unknown option: %s\n' "$option" >&2; exit 2 ;;
  esac
done

export PATH="$HOME/.local/bin:$PATH"
if [ "$codex" -eq 1 ] || [ "$opencode" -eq 1 ]; then
  command -v npm >/dev/null 2>&1 || { printf 'npm is required; run claude-install.sh --node-only first\n' >&2; exit 1; }
fi

if [ "$codex" -eq 1 ]; then
  install_npm_harness codex @openai/codex
  for filename in config.toml AGENTS.md; do
    fetch "$RAW_BASE/config/harnesses/codex/$filename" "$TEMP_DIR/$filename"
    backup_and_install "$TEMP_DIR/$filename" "$HOME/.codex/$filename"
  done
fi

if [ "$opencode" -eq 1 ]; then
  install_npm_harness opencode opencode-ai
  fetch "$RAW_BASE/config/harnesses/opencode/AGENTS.md" "$TEMP_DIR/opencode-AGENTS.md"
  backup_and_install "$TEMP_DIR/opencode-AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
fi

if [ "$molt" -eq 1 ] && ! command -v molt >/dev/null 2>&1; then
  fetch https://raw.githubusercontent.com/Sergio-prog/molt/main/install.sh "$TEMP_DIR/molt-install.sh"
  MOLT_INSTALL_DIR="$HOME/.local/bin" sh "$TEMP_DIR/molt-install.sh"
fi

printf '[fotex] Selected harnesses are ready. Sign in to each CLI on this host.\n'
