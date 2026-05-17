# Interactive shell behavior: keymap, options, history, terminal hooks.

bindkey -e
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[d' kill-word
bindkey '^[^?' backward-kill-word
bindkey '\e\x7f' backward-kill-word

setopt prompt_subst
setopt interactive_comments
setopt extended_glob
setopt numeric_glob_sort
setopt share_history
setopt hist_ignore_space hist_ignore_all_dups hist_find_no_dups hist_reduce_blanks hist_verify

export REPORTTIME=${REPORTTIME:-2}
export KEYTIMEOUT=${KEYTIMEOUT:-15}

HISTFILE=${HISTFILE:-${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history}
HISTSIZE=${HISTSIZE:-100000}
SAVEHIST=${SAVEHIST:-100000}
export HISTFILE HISTSIZE SAVEHIST

if [[ -t 0 ]]; then
  GPG_TTY=$(tty 2>/dev/null) && export GPG_TTY
fi

# Window-title hook: only attach when the terminal can actually render an
# OSC 2 sequence. `add-zsh-hook` already dedupes by function name, so the
# `_M1ZSH_LOADED_*` per-module guard plus this terminal check together make
# the hook installation fully idempotent.
if [[ ${M1ZSH_ENABLE_TITLE:-1} == 1 \
      && ${TERM:-dumb} != dumb \
      && ${TERM:-dumb} != linux \
      && ${TERM:-dumb} != unknown ]]; then
  autoload -Uz add-zsh-hook
  m1zsh_title_precmd() {
    emulate -L zsh
    local dir=${PWD/#$HOME/~}
    print -n -- $'\e]2;'
    print -n -- "$dir"
    print -n -- $'\a'
  }
  add-zsh-hook precmd m1zsh_title_precmd
fi
