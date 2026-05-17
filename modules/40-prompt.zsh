# Prompt defaults. Override in the personal overlay.

if [[ -n ${M1ZSH_PROMPT_FILE:-} && -r $M1ZSH_PROMPT_FILE ]]; then
  source "$M1ZSH_PROMPT_FILE"
elif [[ -z ${PROMPT:-} || $PROMPT == '%m%# ' ]]; then
  PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '
fi
