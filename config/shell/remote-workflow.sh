case ":$PATH:" in
  *:"$HOME/.local/bin":*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac

case ":$PATH:" in
  *:"$HOME/.bun/bin":*) ;;
  *) PATH="$HOME/.bun/bin:$PATH" ;;
esac

export PATH

if command -v micro >/dev/null 2>&1; then
  export EDITOR=micro
  export VISUAL=micro
  export SUDO_EDITOR=micro
fi
