# Archive helpers.

tgz() { emulate -L zsh; tar -cf - "$1" | gzip -9 > "${1%/}.tar.gz"; }
tbz() { emulate -L zsh; tar -cf - "$1" | bzip2 -9 > "${1%/}.tar.bz2"; }
txz() { emulate -L zsh; tar -cf - "$1" | xz -6 > "${1%/}.tar.xz"; }
tzst() { emulate -L zsh; tar -cf - "$1" | zstd -19 > "${1%/}.tar.zst"; }

untgz() { emulate -L zsh; tar -xzf "$1"; }
untbz() { emulate -L zsh; tar -xjf "$1"; }
untxz() { emulate -L zsh; tar -xJf "$1"; }
untzst() { emulate -L zsh; zstd -dc "$1" | tar -xf -; }

archive-ls() {
  emulate -L zsh
  local file=${1:-}
  [[ -n $file ]] || { print -u2 -- 'usage: archive-ls <archive>'; return 2; }
  case $file in
    (*.tar.gz|*.tgz) tar -tzf "$file" ;;
    (*.tar.bz2|*.tbz2) tar -tjf "$file" ;;
    (*.tar.xz|*.txz) tar -tJf "$file" ;;
    (*.tar.zst) zstd -dc "$file" | tar -tf - ;;
    (*.zip) unzip -l "$file" ;;
    (*.tar) tar -tf "$file" ;;
    (*) print -u2 -- "archive-ls: unknown format: $file"; return 1 ;;
  esac
}
