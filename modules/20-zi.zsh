# Zi bootstrap. Install Zi separately; this repo does not vendor it.

: "${ZI_HOME:=$HOME/.config/zi}"

[[ ${M1ZSH_SKIP_ZI:-0} == 1 ]] && return 0

if [[ -r "$ZI_HOME/init.zsh" ]]; then
  source "$ZI_HOME/init.zsh" || { m1zsh_warn "failed to source Zi from $ZI_HOME"; return 0; }
  (( ${+functions[zzinit]} )) && zzinit
else
  m1zsh_warn "Zi not found at $ZI_HOME; plugin modules will fall back or skip"
fi
