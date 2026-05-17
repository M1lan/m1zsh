# Public tool snippets. Missing tools are skipped by their snippets.

[[ ${M1ZSH_DISABLE_TOOL_ADAPTERS:-0} == 1 ]] && return 0

m1zsh_load_snippet snippets/archive.zsh
m1zsh_load_snippet snippets/git.zsh
m1zsh_load_snippet snippets/zi-auto-update.zsh

m1zsh_load_snippet snippets/tool-adapters/fzf.zsh 0a
m1zsh_load_snippet snippets/tool-adapters/zoxide.zsh 0e
m1zsh_load_snippet snippets/tool-adapters/atuin.zsh 1b
m1zsh_load_snippet snippets/tool-adapters/mise.zsh 1c
m1zsh_load_snippet snippets/tool-adapters/goenv.zsh 2
m1zsh_load_snippet snippets/tool-adapters/ghcup.zsh 2
m1zsh_load_snippet snippets/tool-adapters/sdkman.zsh 2
m1zsh_load_snippet snippets/tool-adapters/bun.zsh 2
