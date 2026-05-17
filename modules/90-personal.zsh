# Local-only personal overlay. Files loaded here must stay outside git.

typeset _m1zsh_personal_file _m1zsh_personal_dir _m1zsh_personal_snippet
_m1zsh_personal_file=${M1ZSH_PERSONAL_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/m1zsh/personal.zsh}
_m1zsh_personal_dir=${M1ZSH_PERSONAL_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/m1zsh/local}

[[ -r $_m1zsh_personal_file ]] && source "$_m1zsh_personal_file"

if [[ -d $_m1zsh_personal_dir ]]; then
  for _m1zsh_personal_snippet in "$_m1zsh_personal_dir"/*.zsh(N); do
    source "$_m1zsh_personal_snippet"
  done
fi

unset _m1zsh_personal_file _m1zsh_personal_dir _m1zsh_personal_snippet
