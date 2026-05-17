# m1zsh optional .zshenv entrypoint. Keep this non-interactive safe.

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
export XDG_DATA_HOME XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME

TMPPREFIX="${TMPDIR:-/tmp/}zsh"
export TMPPREFIX

typeset -gaU path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/.cargo/bin"
  "$HOME/go/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $path
)

: "${EDITOR:=vi}"
: "${VISUAL:=$EDITOR}"
: "${PAGER:=less}"
export EDITOR VISUAL PAGER

# Optional external env overlay. This path is intentionally outside the repo.
if [[ -n ${M1ZSH_ENV_LOCAL:-} && -r $M1ZSH_ENV_LOCAL ]]; then
  source "$M1ZSH_ENV_LOCAL"
fi
