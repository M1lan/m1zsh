# purpose: run a git command in parallel across every nested .git repo under CWD
# deps:    git, zargs (autoloaded zsh built-in)
# env:     M1ZSH_GIT_FOREACH_JOBS (parallel job count, default 8)
# exits:   0 if every invocation succeeded, non-zero if any failed
# source:  Adapted from author's mein-zsh `git-foreach-zsh`, MIT.

command -v git > /dev/null 2>&1 || return 0

autoload -Uz zargs 2> /dev/null

# Usage:
#   git-foreach status --short
#   git-foreach fetch --all --prune
git-foreach() {
  emulate -L zsh
  setopt local_options extended_glob null_glob
  if (( $# == 0 )); then
    print -u2 -- 'usage: git-foreach <git-args>...'
    return 2
  fi
  local -a repos=( **/.git(/N:h) )
  if (( ${#repos[@]} == 0 )); then
    print -u2 -- 'git-foreach: no nested git repositories under CWD'
    return 0
  fi
  local -i jobs=${M1ZSH_GIT_FOREACH_JOBS:-8}
  zargs -P "$jobs" -I {} -- "${repos[@]}" -- git -C {} "$@"
}
