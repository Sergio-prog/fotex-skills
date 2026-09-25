#!/bin/sh
set -eu

umask 022

RAW_BASE=${FOTEX_RAW_BASE:-https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main}
MICRO_VERSION=${MICRO_VERSION:-2.0.15}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/fotex-ghostty.XXXXXX")

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
  for command_name in tar gzip sha256sum tic tmux; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing=true
    fi
  done

  if [ "$missing" = false ]; then
    return
  fi

  say "Installing terminal prerequisites"
  if command -v apt-get >/dev/null 2>&1; then
    as_root apt-get update -qq
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates coreutils gzip ncurses-bin tar tmux
  elif command -v dnf >/dev/null 2>&1; then
    as_root dnf install -y ca-certificates coreutils gzip ncurses tar tmux
  elif command -v apk >/dev/null 2>&1; then
    as_root apk add ca-certificates coreutils gzip ncurses tar tmux
  elif command -v pacman >/dev/null 2>&1; then
    as_root pacman -Sy --needed --noconfirm ca-certificates coreutils gzip ncurses tar tmux
  else
    die "install tar, gzip, sha256sum, tic, and tmux, then rerun this script"
  fi
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

install_micro() {
  case "$(uname -m)" in
    x86_64 | amd64)
      platform=linux64-static
      ;;
    aarch64 | arm64)
      platform=linux-arm64
      ;;
    *)
      die "Micro is not packaged by this installer for architecture $(uname -m)"
      ;;
  esac

  micro_binary=$HOME/.local/bin/micro
  if [ -x "$micro_binary" ] && "$micro_binary" -version 2>/dev/null | grep -Fq "$MICRO_VERSION"; then
    say "Micro $MICRO_VERSION is already installed"
    return
  fi

  archive=micro-$MICRO_VERSION-$platform.tar.gz
  release_base=https://github.com/micro-editor/micro/releases/download/v$MICRO_VERSION

  say "Installing Micro $MICRO_VERSION"
  fetch "$release_base/$archive" "$TEMP_DIR/$archive"
  fetch "$release_base/$archive.sha" "$TEMP_DIR/$archive.sha"
  (
    cd "$TEMP_DIR"
    sha256sum -c "$archive.sha"
  )
  tar -xzf "$TEMP_DIR/$archive" -C "$TEMP_DIR"
  extracted_binary=$(find "$TEMP_DIR" -type f -name micro -perm -u+x | head -n 1)
  [ -n "$extracted_binary" ] || die "the Micro archive did not contain an executable"
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$extracted_binary" "$micro_binary"
}

install_micro_config() {
  say "Installing Micro configuration"
  for relative_path in settings.json bindings.json init.lua; do
    fetch "$RAW_BASE/config/micro/$relative_path" "$TEMP_DIR/$relative_path"
    backup_and_install "$TEMP_DIR/$relative_path" "$HOME/.config/micro/$relative_path" 0644
  done
}

install_terminfo() {
  say "Installing xterm-ghostty terminfo"
  fetch "$RAW_BASE/config/ghostty/xterm-ghostty.terminfo" "$TEMP_DIR/xterm-ghostty.terminfo"
  mkdir -p "$HOME/.terminfo"
  tic -x -o "$HOME/.terminfo" "$TEMP_DIR/xterm-ghostty.terminfo"
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
}

[ "$(uname -s)" = Linux ] || die "ghostty-install.sh is intended for Linux VPS hosts"
command -v curl >/dev/null 2>&1 || die "curl is required"

ensure_packages
install_micro
install_micro_config
install_terminfo
install_shell_config

export PATH="$HOME/.local/bin:$PATH"
say "Installed $(micro -version | head -n 1)"
say "Use: tmux new -A -s work, then micro <file>"
say "Paste with your local terminal shortcut. In cmux on macOS, use Command-V."
