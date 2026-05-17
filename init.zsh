# m1zsh interactive entrypoint. Source this from ~/.zshrc.

[[ -o interactive ]] || return 0

if [[ -z ${M1ZSH_HOME:-} ]]; then
  typeset -g M1ZSH_HOME="${${(%):-%x}:A:h}"
fi

source "$M1ZSH_HOME/lib/m1zsh.zsh"

m1zsh_source modules/00-env.zsh
m1zsh_source modules/10-interactive.zsh
m1zsh_source modules/20-zi.zsh
m1zsh_source modules/30-completion.zsh
m1zsh_source modules/40-prompt.zsh
m1zsh_source modules/50-plugins.zsh
m1zsh_source modules/60-aliases.zsh
m1zsh_source modules/70-tools.zsh
m1zsh_source modules/90-personal.zsh
