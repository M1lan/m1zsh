# Git helpers that are safe for public defaults.

glogn() {
  emulate -L zsh
  git log --oneline --decorate --graph -n "${1:-20}"
}

glogf() {
  emulate -L zsh
  git log --follow --oneline --decorate -- "$@"
}

git-dirty() {
  emulate -L zsh
  setopt local_options extended_glob null_glob
  local dir status
  for dir in **/.git(/N:h); do
    status=$(git -C "$dir" status --porcelain 2>/dev/null) || continue
    [[ -n $status ]] && print -r -- "$dir"
  done
}
