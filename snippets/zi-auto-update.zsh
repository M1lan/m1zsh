# Throttled, background Zi update helper.

zmodload zsh/stat 2>/dev/null
zmodload zsh/datetime 2>/dev/null

: "${ZI_AUTO_UPDATE_DAYS:=7}"
typeset -g _M1ZSH_ZI_AU_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/m1zsh"
typeset -g _M1ZSH_ZI_AU_STAMP="$_M1ZSH_ZI_AU_DIR/zi-last-update"
typeset -g _M1ZSH_ZI_AU_LOG="$_M1ZSH_ZI_AU_DIR/zi-update.log"
mkdir -p -- "$_M1ZSH_ZI_AU_DIR" 2>/dev/null || return 0

m1zsh-zi-update() {
  emulate -L zsh
  if ! (( ${+functions[zi]} )); then
    print -u2 -- 'm1zsh-zi-update: zi is not loaded'
    return 1
  fi
  zi update "$@"
}

m1zsh-zi-update-status() {
  emulate -L zsh
  if [[ -e $_M1ZSH_ZI_AU_STAMP ]]; then
    print -r -- "last update: $_M1ZSH_ZI_AU_STAMP"
  else
    print -r -- 'last update: never'
  fi
  [[ -r $_M1ZSH_ZI_AU_LOG ]] && tail -20 -- "$_M1ZSH_ZI_AU_LOG"
}
