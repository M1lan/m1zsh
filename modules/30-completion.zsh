# Completion subsystem.
#
# This module is wrapped by the per-module guard in `m1zsh_source`, so
# compinit runs at most once per shell. When Zi is loaded we delegate to
# `zicompinit` / `zicdreplay` so Zi-managed plugin completions are picked
# up without double-initialising the completion system.
#
# Environment variables:
#   M1ZSH_DISABLE_COMPLETIONS=1  Skip the completion subsystem entirely.
#                                Useful for embedded shells, CI runners,
#                                or extremely constrained environments
#                                where compinit is undesirable.
#   M1ZSH_COMPINIT_INSECURE=1    Keep `compinit -i` (skip insecure dirs)
#                                but suppress the one-shot warning that
#                                lists which directories were skipped.
#                                For users who knowingly run on a
#                                multi-user host or with shared group
#                                ownership of an fpath dir.
#   ZCACHEDIR                    Cache directory; defaults to
#                                ${XDG_CACHE_HOME:-$HOME/.cache}/zsh.
#                                The compiled dump lives at
#                                $ZCACHEDIR/.zcompdump(.zwc).

typeset -gU fpath

if [[ ${M1ZSH_DISABLE_COMPLETIONS:-0} == 1 ]]; then
  return 0
fi

m1zsh_prepend_fpath "$M1ZSH_HOME/completions" "$HOME/.local/share/zsh/site-functions"
if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  m1zsh_prepend_fpath "$HOMEBREW_PREFIX/share/zsh/site-functions" "$HOMEBREW_PREFIX/share/zsh-completions"
fi

# Completion behaviour. zstyles are global and unaffected by `emulate -L`
# scoping in the init function below, so they live at module level.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZCACHEDIR:-$HOME/.cache/zsh}/completions"
# Case-insensitive -> hyphen/underscore equivalence -> partial-word ->
# substring matching. Each clause is only tried if the previous one
# produced no completions.
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{-_}={_-}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose true
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*:messages'     format '%F{yellow}── %d ──%f'
zstyle ':completion:*:warnings'     format '%F{red}── no matches: %d ──%f'
if [[ -n ${LS_COLORS:-} ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

if m1zsh_zi_ready; then
  zi light zsh-users/zsh-completions
  zicompinit
  zicdreplay
  return 0
fi

# Standalone path: explicit compinit with audit, freshness-aware cache,
# and zcompile of the dump for ~30% faster subsequent loads.
_m1zsh_compinit_run() {
  emulate -L zsh
  setopt extended_glob

  local zcompdump="${ZCACHEDIR:-$HOME/.cache/zsh}/.zcompdump"
  mkdir -p "${zcompdump:h}" 2> /dev/null || true

  autoload -Uz compinit compaudit

  # Audit fpath for group/world-writable dirs. Warn once with the
  # standard remediation. `compinit -i` still skips them either way.
  if [[ ${M1ZSH_COMPINIT_INSECURE:-0} != 1 ]]; then
    local -a insecure
    insecure=( ${(f)"$(compaudit 2> /dev/null)"} )
    if (( ${#insecure} > 0 )); then
      m1zsh_warn "compaudit found ${#insecure} insecure fpath dir(s):"
      local d
      for d in $insecure; do
        m1zsh_warn "  $d"
      done
      m1zsh_warn "fix with: compaudit | xargs chmod g-w,o-w"
      m1zsh_warn "(silence with: export M1ZSH_COMPINIT_INSECURE=1)"
    fi
  fi

  # Rebuild the dump if it is missing, more than 24h old, or staler
  # than any fpath entry; otherwise load the cached dump quickly.
  local rebuild=0
  if [[ ! -f $zcompdump ]]; then
    rebuild=1
  elif [[ -n $zcompdump(#qN.mh+24) ]]; then
    rebuild=1
  else
    local fp
    for fp in $fpath; do
      if [[ -d $fp && $fp -nt $zcompdump ]]; then
        rebuild=1
        break
      fi
    done
  fi

  if (( rebuild )); then
    compinit -i -d "$zcompdump"
  else
    compinit -C -d "$zcompdump"
  fi

  # Pre-compile the dump if missing or stale relative to its source.
  # Best-effort: a failure here is never fatal (read-only $ZCACHEDIR,
  # ENOSPC, ...); the next shell will retry.
  if [[ -s $zcompdump ]]; then
    if [[ ! -s ${zcompdump}.zwc || $zcompdump -nt ${zcompdump}.zwc ]]; then
      zcompile "$zcompdump" 2> /dev/null || true
    fi
  fi
}

_m1zsh_compinit_run
unset -f _m1zsh_compinit_run
