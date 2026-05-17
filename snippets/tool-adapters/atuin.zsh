# atuin integration.

[[ -r "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
(( ${+commands[atuin]} )) && eval "$(atuin init zsh --disable-up-arrow)"
