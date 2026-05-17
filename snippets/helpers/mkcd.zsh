# Purpose: create one directory tree and enter it with mkcd/take.
# Deps: mkdir (external); cd, pwd, and print are zsh builtins.
# Env vars: none.
# Exit codes: 0 on success, 2 for bad usage, otherwise mkdir/cd failure.
# Attribution: sanitized from local mein-zsh mkcd helper; hardened for m1zsh.

command -v mkdir >/dev/null 2>&1 || return 0

mkcd() {
  emulate -L zsh
  (( $# == 1 )) || { print -u2 -- 'usage: mkcd <dir>'; return 2; }
  mkdir -p -- "$1" && cd -- "$1" && pwd
}

take() {
  emulate -L zsh
  mkcd "$@"
}
