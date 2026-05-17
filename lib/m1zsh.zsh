# Shared helpers for m1zsh modules.

m1zsh_warn() {
  print -u2 -- "m1zsh: $*"
}

m1zsh_have() {
  (( ${+commands[$1]} ))
}

m1zsh_source() {
  local rel=$1 file
  file="$M1ZSH_HOME/$rel"
  if [[ ! -r $file ]]; then
    m1zsh_warn "missing module: $rel"
    return 1
  fi
  source "$file"
}

m1zsh_source_if_exists() {
  local file=$1
  [[ -r $file ]] && source "$file"
}

m1zsh_prepend_path() {
  local dir
  typeset -gU path
  for dir in "$@"; do
    [[ -d $dir ]] && path=("$dir" $path)
  done
}

m1zsh_prepend_fpath() {
  local dir
  typeset -gU fpath
  for dir in "$@"; do
    [[ -d $dir ]] && fpath=("$dir" $fpath)
  done
}

m1zsh_zi_ready() {
  (( ${+functions[zi]} ))
}

m1zsh_load_snippet() {
  local rel=$1 wait=${2:-} file
  file="$M1ZSH_HOME/$rel"
  [[ -r $file ]] || return 0

  if m1zsh_zi_ready; then
    if [[ -n $wait ]]; then
      zi ice "wait${wait}" lucid nocd is-snippet
    else
      zi ice lucid nocd is-snippet
    fi
    zi snippet "$file"
  else
    source "$file"
  fi
}
