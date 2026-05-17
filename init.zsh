# m1zsh interactive entrypoint. Source this from ~/.zshrc.
#
# Re-sourcing is a no-op: the `_M1ZSH_LOADED` sentinel short-circuits the
# whole file, and `m1zsh_source` guards every module individually. Run
# `m1zsh_reload` to force a fresh re-source during development.

# Refuse to run under a non-zsh interpreter. The check uses POSIX-ish
# syntax so it is parseable even if bash or sh accidentally sources us.
if [ -z "${ZSH_VERSION:-}" ]; then
  echo "m1zsh: requires zsh (ZSH_VERSION not set); skipping" >&2
  return 0 2>/dev/null || exit 0
fi

[[ -o interactive ]] || return 0

# Without HOME there is nothing safe to do: XDG defaults, history files,
# personal overlays all need it. Bail with one warning rather than crash.
if [[ -z ${HOME:-} ]]; then
  print -u2 -- 'm1zsh: $HOME is unset; skipping load'
  return 0
fi

if (( ${_M1ZSH_LOADED:-0} )); then
  return 0
fi

if [[ -z ${M1ZSH_HOME:-} ]]; then
  typeset -g M1ZSH_HOME="${${(%):-%x}:A:h}"
fi

source "$M1ZSH_HOME/lib/m1zsh.zsh"

m1zsh_source modules/00-env.zsh
m1zsh_source modules/10-interactive.zsh
m1zsh_source modules/20-zi.zsh
m1zsh_source modules/30-completion.zsh
m1zsh_source modules/40-prompt.zsh
m1zsh_source modules/50-plugins.zsh
m1zsh_source modules/60-aliases.zsh
m1zsh_source modules/70-tools.zsh
m1zsh_source modules/90-personal.zsh

typeset -g _M1ZSH_LOADED=1
