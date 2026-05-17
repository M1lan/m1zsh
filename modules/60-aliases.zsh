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
