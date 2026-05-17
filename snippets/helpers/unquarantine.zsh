# purpose: strip macOS Gatekeeper's com.apple.quarantine xattr (recursive)
# deps:    xattr (macOS built-in); returns 0 elsewhere via the guard below
# env:     none
# exits:   0 on success or when xattr is unavailable; xattr's exit code otherwise
# source:  Adapted from author's mein-zsh `unquarantine`, MIT.

command -v xattr > /dev/null 2>&1 || return 0

# Usage:
#   unquarantine             # strip from current directory tree
#   unquarantine FILE...     # strip from given paths (files or trees)
unquarantine() {
  emulate -L zsh
  xattr -dr com.apple.quarantine "${@:-.}"
}
