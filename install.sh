#!/bin/sh
set -eu

RAW_BASE=${FOTEX_RAW_BASE:-https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/fotex-install.XXXXXX")
MENU_ACTIVE=false

cleanup() {
  if [ "$MENU_ACTIVE" = true ]; then
    stty "$TTY_STATE" <&3
    printf '\033[?25h\033[?1049l' >&3
  fi
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

select_all() {
  micro=1 claude=1 codex=1 opencode=1 molt=1 chainq=1
}

select_none() {
  micro=0 claude=0 codex=0 opencode=0 molt=0 chainq=0
}

select_only() {
  names=$1
  case "$names" in
    '' | ,* | *, | *,,* | *[!a-z,]*) printf 'invalid --only list: %s\n' "$names" >&2; exit 2 ;;
  esac
  select_none
  remaining=$names
  while :; do
    case "$remaining" in
      *,*) name=${remaining%%,*}; remaining=${remaining#*,} ;;
      *) name=$remaining; remaining= ;;
    esac
    case "$name" in
      micro) micro=1 ;;
      claude) claude=1 ;;
      codex) codex=1 ;;
      opencode) opencode=1 ;;
      molt) molt=1 ;;
      chainq) chainq=1 ;;
      *) printf 'unknown package: %s\n' "$name" >&2; exit 2 ;;
    esac
    [ -n "$remaining" ] || break
  done
}

selected() {
  case "$1" in
    1) value=$micro ;;
    2) value=$claude ;;
    3) value=$codex ;;
    4) value=$opencode ;;
    5) value=$molt ;;
    6) value=$chainq ;;
  esac
}

toggle() {
  selected "$1"
  if [ "$value" -eq 1 ]; then value=0; else value=1; fi
  case "$1" in
    1) micro=$value ;;
    2) claude=$value ;;
    3) codex=$value ;;
    4) opencode=$value ;;
    5) molt=$value ;;
    6) chainq=$value ;;
  esac
}

draw_option() {
  number=$1
  label=$2
  selected "$number"
  if [ "$value" -eq 1 ]; then mark=x; else mark=' '; fi
  if [ "$focus" -eq "$number" ]; then pointer='>'; else pointer=' '; fi
  printf '  %s [%s] %s\n' "$pointer" "$mark" "$label" >&3
}

draw_menu() {
  printf '\033[H\033[J' >&3
  printf 'fotex setup\n\n' >&3
  draw_option 1 'Micro, tmux, Ghostty terminfo'
  draw_option 2 'Claude Code, Bun, plugins'
  draw_option 3 'Codex'
  draw_option 4 'OpenCode'
  draw_option 5 'molt'
  draw_option 6 'chainq'
  printf '\n  Up/Down: move   Space: toggle   A: all   N: none\n' >&3
  printf '  Enter: install   Q: cancel\n' >&3
  if [ "$micro$claude$codex$opencode$molt$chainq" = 000000 ]; then
    printf '\n  Select at least one package.\n' >&3
  fi
}

interactive_selection() {
  if [ -t 2 ]; then
    exec 3<&2
  elif (stty -g </dev/tty) >/dev/null 2>&1; then
    exec 3<>/dev/tty
  else
    printf 'no terminal available; use --all or --only=micro,claude,...\n' >&2
    exit 2
  fi
  TTY_STATE=$(stty -g <&3 2>/dev/null) || {
    printf 'no terminal available; use --all or --only=micro,claude,...\n' >&2
    exit 2
  }
  stty -echo -icanon min 1 time 0 <&3
  printf '\033[?1049h\033[?25l' >&3
  MENU_ACTIVE=true
  focus=1
  select_all
  while :; do
    draw_menu
    key=$(dd bs=1 count=1 <&3 2>/dev/null)
    case "$key" in
      '' | "$(printf '\r')")
        [ "$micro$claude$codex$opencode$molt$chainq" != 000000 ] && break
        ;;
      ' ') toggle "$focus" ;;
      a | A) select_all ;;
      n | N) select_none ;;
      q | Q) exit 0 ;;
      "$(printf '\033')")
        sequence=$(dd bs=1 count=2 <&3 2>/dev/null)
        case "$sequence" in
          '[A') focus=$((focus - 1)); [ "$focus" -ge 1 ] || focus=6 ;;
          '[B') focus=$((focus + 1)); [ "$focus" -le 6 ] || focus=1 ;;
        esac
        ;;
    esac
  done
  stty "$TTY_STATE" <&3
  printf '\033[?25h\033[?1049l' >&3
  MENU_ACTIVE=false
  exec 3<&-
}

select_none
case "${1:-}" in
  '') interactive_selection ;;
  --all) [ "$#" -eq 1 ] || { printf 'unexpected arguments\n' >&2; exit 2; }; select_all ;;
  --only=*) [ "$#" -eq 1 ] || { printf 'unexpected arguments\n' >&2; exit 2; }; select_only "${1#--only=}" ;;
  --help)
    printf 'usage: sh install.sh [--all | --only=micro,claude,codex,opencode,molt,chainq]\n'
    exit 0
    ;;
  *) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
esac

fetch_and_run() {
  script=$1
  shift
  curl -fsSL "$RAW_BASE/$script" -o "$TEMP_DIR/$script"
  FOTEX_RAW_BASE=$RAW_BASE sh "$TEMP_DIR/$script" "$@"
}

if [ "$micro" -eq 1 ]; then
  fetch_and_run ghostty-install.sh
fi

if [ "$claude" -eq 1 ]; then
  if [ "$chainq" -eq 1 ]; then
    fetch_and_run claude-install.sh
  else
    fetch_and_run claude-install.sh --no-chainq
  fi
elif [ "$codex" -eq 1 ] || [ "$opencode" -eq 1 ]; then
  fetch_and_run claude-install.sh --node-only
fi

set --
[ "$codex" -eq 0 ] || set -- "$@" --codex
[ "$opencode" -eq 0 ] || set -- "$@" --opencode
[ "$molt" -eq 0 ] || set -- "$@" --molt
if [ "$#" -gt 0 ]; then
  fetch_and_run harness-install.sh "$@"
fi

if [ "$chainq" -eq 1 ] && [ "$claude" -eq 0 ]; then
  curl -fsSL https://raw.githubusercontent.com/Sergio-prog/chainq/main/install.sh -o "$TEMP_DIR/chainq-install.sh"
  sh "$TEMP_DIR/chainq-install.sh"
fi
