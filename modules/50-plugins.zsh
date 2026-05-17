# Zi-managed plugin groups.

m1zsh_zi_ready || return 0

# Fast interactive affordances after the first prompt.
zi wait lucid for \
  zsh-users/zsh-history-substring-search \
  z-shell/F-Sy-H

if [[ ${M1ZSH_ENABLE_AUTOSUGGEST:-0} == 1 ]]; then
  zi ice wait'0b' lucid atload'_zsh_autosuggest_start'
  zi light zsh-users/zsh-autosuggestions
fi

# Common OMZ snippets without loading oh-my-zsh.sh.
if [[ ${M1ZSH_ENABLE_OMZ:-1} == 1 ]]; then
  zi wait'1' lucid for \
    OMZP::git \
    OMZP::docker \
    OMZP::docker-compose \
    OMZP::kubectl \
    OMZP::colored-man-pages
fi
