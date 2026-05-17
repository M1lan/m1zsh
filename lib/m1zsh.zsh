# Shared helpers for m1zsh modules.
#
# All helpers assume the caller is interactive zsh. They are written to be
# safe under `setopt nounset` and to be re-sourced any number of times
# without side effects.

m1zsh_warn() {
  emulate -L zsh
  print -u2 -- "m1zsh: $*"
}

m1zsh_have() {
  emulate -L zsh
  (( ${+commands[$1]} ))
}

# Translate a relative module path into a guard variable name, e.g.
# `modules/30-completion.zsh` -> `_M1ZSH_LOADED_modules_30_completion_zsh`.
m1zsh_guard_var() {
  emulate -L zsh
  local rel=$1
  local key=${rel//[^A-Za-z0-9]/_}
  print -r -- "_M1ZSH_LOADED_${key}"
}

# Source a module relative to $M1ZSH_HOME, exactly once per shell. The
# per-module guard lets callers re-source `init.zsh` (or this file) without
# duplicating side effects.
#
# IMPORTANT: this helper deliberately omits `emulate -L zsh`. Module files
# call `setopt` to configure the interactive shell (prompt_subst,
# share_history, extended_glob, ...). `emulate -L` would activate
# LOCAL_OPTIONS and silently revert every one of those when the function
# returns. The function body uses only nounset-safe constructs, so the
# absence of `emulate -L zsh` is safe.
m1zsh_source() {
  local rel=$1 file key
  file="${M1ZSH_HOME:-}/$rel"
  key=$(m1zsh_guard_var "$rel")
  if (( ${(P)+key} )) && [[ ${(P)key} == 1 ]]; then
    return 0
  fi
  if [[ ! -r $file ]]; then
    m1zsh_warn "missing module: $rel"
    return 1
  fi
  source "$file" && typeset -g "$key=1"
}

m1zsh_source_if_exists() {
  emulate -L zsh
  local file=${1:-}
  [[ -n $file && -r $file ]] && source "$file"
}

m1zsh_prepend_path() {
  emulate -L zsh
  local dir
  typeset -gU path
  for dir in "$@"; do
    [[ -n $dir && -d $dir ]] && path=("$dir" $path)
  done
}

m1zsh_prepend_fpath() {
  emulate -L zsh
  local dir
  typeset -gU fpath
  for dir in "$@"; do
    [[ -n $dir && -d $dir ]] && fpath=("$dir" $fpath)
  done
}

m1zsh_zi_ready() {
  emulate -L zsh
  (( ${+functions[zi]} ))
}

m1zsh_load_snippet() {
  emulate -L zsh
  local rel=$1 wait=${2:-} file
  file="${M1ZSH_HOME:-}/$rel"
  [[ -r $file ]] || return 0

  typeset -gaU _M1ZSH_LOADED_SNIPPETS

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
  _M1ZSH_LOADED_SNIPPETS+=("$rel")
}

# Force the next `m1zsh_source` (or `source init.zsh`) to re-run everything.
# Useful for developing modules in-place.
m1zsh_reload() {
  emulate -L zsh
  local var
  for var in ${(k)parameters[(I)_M1ZSH_LOADED*]}; do
    unset $var
  done
  unset _M1ZSH_LOADED_SNIPPETS 2>/dev/null
}

# Stub: lazy-load lib/doctor.zsh on first invocation. Keeps doctor (a few
# hundred lines and never used in the hot path) out of every interactive
# shell's memory until explicitly asked for.
m1zsh_doctor() {
  emulate -L zsh
  local impl="${M1ZSH_HOME:-}/lib/doctor.zsh"
  if [[ ! -r $impl ]]; then
    print -u2 -- "m1zsh_doctor: ${impl} not readable"
    return 127
  fi
  unfunction m1zsh_doctor 2>/dev/null
  source "$impl"
  m1zsh_doctor "$@"
}
