# fzf integration.

if (( ${+commands[fzf]} )); then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [[ -n ${HOMEBREW_PREFIX:-} && -r $HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh ]]; then
    source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  fi
fi
