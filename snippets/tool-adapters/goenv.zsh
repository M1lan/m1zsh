# goenv integration.

[[ -z ${GOENV_SHELL:-} ]] && (( ${+commands[goenv]} )) && eval "$(goenv init -)"
