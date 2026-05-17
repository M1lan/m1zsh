# Public aliases and tiny helpers.

alias readme='${PAGER:-less} README.md'

if m1zsh_have eza; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --group-directories-first --git'
  alias la='eza -a --group-directories-first'
  alias tree='eza --tree --group-directories-first'
fi

alias gs='git status --short --branch'
alias gd='git diff'
alias gds='git diff --staged'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glo='git log --oneline --decorate'

mkcd() {
  emulate -L zsh
  (( $# == 1 )) || { print -u2 -- 'usage: mkcd <dir>'; return 2; }
  mkdir -p -- "$1" && cd -- "$1"
}

where-all() {
  emulate -L zsh
  (( $# == 1 )) || { print -u2 -- 'usage: where-all <command>'; return 2; }
  print -r -- 'type -af:'
  type -af -- "$1"
  print -r -- 'command -v:'
  command -v -- "$1"
}

# Auto-source small public helpers from snippets/helpers/. Each file is
# self-guarded with `command -v <tool> >/dev/null 2>&1 || return 0`, so
# loading them is safe even when their underlying tools are absent. The
# per-module `_M1ZSH_LOADED_modules_60_aliases_zsh` sentinel set by
# `m1zsh_source` prevents this loop from running twice in one shell.
if [[ -n ${M1ZSH_HOME:-} && -d ${M1ZSH_HOME}/snippets/helpers ]]; then
  local _m1zsh_helper
  for _m1zsh_helper in ${M1ZSH_HOME}/snippets/helpers/*.zsh(N); do
    source "$_m1zsh_helper"
  done
  unset _m1zsh_helper
fi
