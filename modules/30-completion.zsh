# Completion setup. Keep fpath complete before compinit.
#
# This module is wrapped by the per-module guard in `m1zsh_source`, so
# compinit is only ever invoked once per shell. If the user calls compinit
# themselves later they get the standard zsh re-init behaviour; we do not.

typeset -gU fpath

m1zsh_prepend_fpath "$M1ZSH_HOME/completions" "$HOME/.local/share/zsh/site-functions"
if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  m1zsh_prepend_fpath "$HOMEBREW_PREFIX/share/zsh/site-functions" "$HOMEBREW_PREFIX/share/zsh-completions"
fi

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZCACHEDIR:-$HOME/.cache/zsh}/completions"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'm:{-_}={_-}'
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'

if m1zsh_zi_ready; then
  zi light zsh-users/zsh-completions
  zicompinit
  zicdreplay
else
  autoload -Uz compinit
  compinit -d "${ZCACHEDIR:-$HOME/.cache/zsh}/.zcompdump"
fi
