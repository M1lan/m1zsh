# Prompt defaults. Override in the personal overlay.
#
# Selection order:
#   1. M1ZSH_PROMPT_FILE if it points at a readable file.
#   2. A plain ASCII prompt for `NO_COLOR=1`, `TERM=dumb`, or non-tty stdout.
#   3. A coloured default that only triggers if the user has not customised it.

if [[ -n ${M1ZSH_PROMPT_FILE:-} && -r $M1ZSH_PROMPT_FILE ]]; then
  source "$M1ZSH_PROMPT_FILE"
elif [[ -n ${NO_COLOR:-} || ${TERM:-} == dumb || ${TERM:-} == unknown || ! -t 1 ]]; then
  PROMPT='%n@%m %~ %# '
elif [[ -z ${PROMPT:-} || $PROMPT == '%m%# ' ]]; then
  PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '
fi
