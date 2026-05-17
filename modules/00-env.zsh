# Public interactive environment defaults.

typeset -gU path

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
export XDG_DATA_HOME XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME

: "${ZCACHEDIR:=$XDG_CACHE_HOME/zsh}"
mkdir -p "$ZCACHEDIR" "$XDG_STATE_HOME/zsh" 2>/dev/null || true
export ZCACHEDIR

if m1zsh_have brew; then
  : "${HOMEBREW_PREFIX:=$(brew --prefix 2>/dev/null)}"
  export HOMEBREW_PREFIX
fi

m1zsh_prepend_path \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$HOME/.cargo/bin" \
  "$HOME/go/bin"

if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  m1zsh_prepend_path \
    "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" \
    "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin" \
    "$HOMEBREW_PREFIX/opt/grep/libexec/gnubin" \
    "$HOMEBREW_PREFIX/bin" \
    "$HOMEBREW_PREFIX/sbin"
fi

: "${EDITOR:=vi}"
: "${VISUAL:=$EDITOR}"
: "${PAGER:=less}"
export EDITOR VISUAL PAGER
