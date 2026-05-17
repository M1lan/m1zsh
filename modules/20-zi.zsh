# Zi bootstrap. Install Zi separately; this repo does not vendor it.
#
# Three exit conditions, each silent or single-warning:
#   - M1ZSH_SKIP_ZI=1 -> silent no-op.
#   - ZI_HOME missing or unreadable init.zsh -> one warning, then no-op.
#   - Zi init fails to source -> one warning, then no-op.

: "${ZI_HOME:=${XDG_CONFIG_HOME:-$HOME/.config}/zi}"

if [[ ${M1ZSH_SKIP_ZI:-0} == 1 ]]; then
  return 0
fi

if [[ ! -r "$ZI_HOME/init.zsh" ]]; then
  m1zsh_warn "Zi not found at $ZI_HOME; plugin modules will fall back or skip"
  return 0
fi

if ! source "$ZI_HOME/init.zsh"; then
  m1zsh_warn "failed to source Zi from $ZI_HOME"
  return 0
fi

(( ${+functions[zzinit]} )) && zzinit
