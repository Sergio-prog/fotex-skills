#!/bin/sh
set -eu

umask 022

RAW_BASE=${FOTEX_RAW_BASE:-https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main}
NODE_MAJOR=${NODE_MAJOR:-24}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/fotex-claude.XXXXXX")

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

say() {
  printf '%s\n' "[fotex] $*"
}

die() {
  printf '%s\n' "[fotex] error: $*" >&2
  exit 1
}

fetch() {
  curl -fsSL "$1" -o "$2"
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "root access is required to install missing system packages"
  fi
}

ensure_packages() {
  missing=false
  for command_name in git gh jq tar gzip sha256sum unzip; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing=true
    fi
  done

  if [ "$missing" = false ]; then
    return
  fi

  say "Installing Claude workflow prerequisites"
  if command -v apt-get >/dev/null 2>&1; then
    as_root apt-get update -qq
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates coreutils curl git gh gzip jq tar unzip
  elif command -v dnf >/dev/null 2>&1; then
    as_root dnf install -y ca-certificates coreutils curl git gh gzip jq tar unzip
  elif command -v apk >/dev/null 2>&1; then
    as_root apk add ca-certificates coreutils curl git github-cli gzip jq tar unzip
  elif command -v pacman >/dev/null 2>&1; then
    as_root pacman -Sy --needed --noconfirm ca-certificates coreutils curl git github-cli gzip jq tar unzip
  else
    die "install git, gh, jq, tar, gzip, sha256sum, and unzip, then rerun this script"
  fi
}

ensure_node_packages() {
  for command_name in tar gzip sha256sum; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      if command -v apt-get >/dev/null 2>&1; then
        as_root apt-get update -qq
        as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y coreutils gzip tar
      elif command -v dnf >/dev/null 2>&1; then
        as_root dnf install -y coreutils gzip tar
      elif command -v apk >/dev/null 2>&1; then
        as_root apk add coreutils gzip tar
      elif command -v pacman >/dev/null 2>&1; then
        as_root pacman -Sy --needed --noconfirm coreutils gzip tar
      else
        die "install tar, gzip, and sha256sum, then rerun this script"
      fi
      return
    fi
  done
}

backup_and_install() {
  source_file=$1
  destination=$2
  mode=$3

  mkdir -p "$(dirname "$destination")"
  if [ -f "$destination" ] && cmp -s "$source_file" "$destination"; then
    return
  fi
  if [ -e "$destination" ]; then
    cp -p "$destination" "$destination.bak.$TIMESTAMP"
    say "Backed up $destination"
  fi
  install -m "$mode" "$source_file" "$destination"
}

add_source_line() {
  shell_file=$1
  source_line=". \"\$HOME/.config/fotex/remote-workflow.sh\""
  touch "$shell_file"
  if ! grep -Fqx "$source_line" "$shell_file"; then
    printf '\n%s\n' "$source_line" >>"$shell_file"
  fi
}

install_shell_config() {
  fetch "$RAW_BASE/config/shell/remote-workflow.sh" "$TEMP_DIR/remote-workflow.sh"
  backup_and_install "$TEMP_DIR/remote-workflow.sh" "$HOME/.config/fotex/remote-workflow.sh" 0644
  add_source_line "$HOME/.profile"

  case "${SHELL##*/}" in
    bash)
      add_source_line "$HOME/.bashrc"
      ;;
    zsh)
      add_source_line "$HOME/.zshrc"
      ;;
  esac

  export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
}

install_node() {
  if command -v node >/dev/null 2>&1; then
    node_major=$(node --version | sed 's/^v//' | cut -d. -f1)
    case "$node_major" in
      '' | *[!0-9]*)
        ;;
      *)
        if [ "$node_major" -ge 20 ]; then
          say "Node.js $(node --version) is already installed"
          return
        fi
        ;;
    esac
  fi

  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64 | Linux-amd64)
      platform=linux-x64
      ;;
    Linux-aarch64 | Linux-arm64)
      platform=linux-arm64
      ;;
    Darwin-arm64 | Darwin-aarch64)
      platform=darwin-arm64
      ;;
    Darwin-x86_64 | Darwin-amd64)
      platform=darwin-x64
      ;;
    *)
      die "Node.js is not packaged by this installer for $(uname -s) $(uname -m)"
      ;;
  esac

  release_base=https://nodejs.org/dist/latest-v$NODE_MAJOR.x
  fetch "$release_base/SHASUMS256.txt" "$TEMP_DIR/node-SHASUMS256.txt"
  archive=$(awk -v suffix="-$platform.tar.gz" '$2 ~ suffix "$" { print $2; exit }' "$TEMP_DIR/node-SHASUMS256.txt")
  [ -n "$archive" ] || die "could not find a Node.js $NODE_MAJOR build for $platform"

  say "Installing Node.js $NODE_MAJOR LTS"
  fetch "$release_base/$archive" "$TEMP_DIR/$archive"
  expected_hash=$(awk -v file="$archive" '$2 == file { print $1 }' "$TEMP_DIR/node-SHASUMS256.txt")
  actual_hash=$(sha256sum "$TEMP_DIR/$archive" | awk '{ print $1 }')
  [ "$expected_hash" = "$actual_hash" ] || die "Node.js checksum verification failed"

  tar -xzf "$TEMP_DIR/$archive" -C "$TEMP_DIR"
  extracted_dir=$(find "$TEMP_DIR" -maxdepth 1 -type d -name 'node-v*' | head -n 1)
  [ -n "$extracted_dir" ] || die "the Node.js archive did not contain the expected directory"
  install_dir=$HOME/.local/share/fotex/$(basename "$extracted_dir")
  mkdir -p "$HOME/.local/share/fotex" "$HOME/.local/bin"
  if [ ! -d "$install_dir" ]; then
    mv "$extracted_dir" "$install_dir"
  fi
  for executable in node npm npx corepack; do
    ln -sfn "$install_dir/bin/$executable" "$HOME/.local/bin/$executable"
  done
  export PATH="$HOME/.local/bin:$PATH"
}

install_bun() {
  if command -v bun >/dev/null 2>&1; then
    say "Bun $(bun --version) is already installed"
    return
  fi

  say "Installing Bun"
  fetch https://bun.sh/install "$TEMP_DIR/bun-install.sh"
  sh "$TEMP_DIR/bun-install.sh"
  export PATH="$HOME/.bun/bin:$PATH"
}

install_claude() {
  if command -v claude >/dev/null 2>&1; then
    say "Claude Code $(claude --version) is already installed"
    return
  fi

  say "Installing Claude Code"
  fetch https://claude.ai/install.sh "$TEMP_DIR/claude-install.sh"
  sh "$TEMP_DIR/claude-install.sh"
  export PATH="$HOME/.local/bin:$PATH"
}

install_chainq() {
  if command -v chainq >/dev/null 2>&1; then
    say "chainq $(chainq --version) is already installed"
    return
  fi

  say "Installing chainq"
  fetch https://raw.githubusercontent.com/Sergio-prog/chainq/main/install.sh "$TEMP_DIR/chainq-install.sh"
  sh "$TEMP_DIR/chainq-install.sh"
  export PATH="$HOME/.local/bin:$PATH"
}

install_claude_config() {
  say "Installing Claude Code settings and instructions"
  for relative_path in settings.json CLAUDE.md; do
    fetch "$RAW_BASE/config/claude/$relative_path" "$TEMP_DIR/$relative_path"
    backup_and_install "$TEMP_DIR/$relative_path" "$HOME/.claude/$relative_path" 0644
  done
}

install_plugins() {
  fetch "$RAW_BASE/config/claude/marketplaces.txt" "$TEMP_DIR/marketplaces.txt"
  fetch "$RAW_BASE/config/claude/plugins.txt" "$TEMP_DIR/plugins.txt"

  while IFS='|' read -r marketplace source; do
    case "$marketplace" in
      '' | \#*) continue ;;
    esac
    if ! claude plugin marketplace list | grep -Fq "$marketplace"; then
      say "Adding Claude marketplace $marketplace"
      claude plugin marketplace add "$source"
    fi
  done <"$TEMP_DIR/marketplaces.txt"

  while IFS= read -r plugin; do
    case "$plugin" in
      '' | \#*) continue ;;
    esac
    if claude plugin list | grep -Fq "$plugin"; then
      say "Updating Claude plugin $plugin"
      claude plugin update "$plugin"
    else
      say "Installing Claude plugin $plugin"
      claude plugin install "$plugin" --scope user --yes
    fi
  done <"$TEMP_DIR/plugins.txt"
}

command -v curl >/dev/null 2>&1 || die "curl is required"
[ "$(uname -s)" = Linux ] || die "claude-install.sh is intended for Linux VPS hosts"
mode=${1:-all}
case "$mode" in
  all | --no-chainq | --node-only) ;;
  *) die "unknown option: $mode" ;;
esac
[ "$#" -le 1 ] || die "unexpected arguments"
if [ "$mode" = --node-only ]; then
  ensure_node_packages
  install_shell_config
  install_node
  say "Node.js is ready"
  exit 0
fi
ensure_packages
install_shell_config
install_node
install_bun
install_claude
if [ "$mode" = all ]; then
  install_chainq
fi
install_claude_config
install_plugins

say "Claude Code workflow installed"
say "Authentication is not copied. Run 'claude' and 'gh auth login' once on this host."
