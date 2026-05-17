set shell := ["bash", "-uc"]

_default:
  @just --list

check: zsh-syntax secrets smoke smoke-strict smoke-twice smoke-setopts smoke-doctor prek-check

zsh-syntax:
  @scripts/check-zsh.bash

secrets:
  @scripts/scan-secrets.bash

smoke:
  @zsh -f -ic 'export M1ZSH_HOME="$PWD" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1; source "$M1ZSH_HOME/init.zsh"; print -- m1zsh-smoke-ok'

# Strict mode: nounset + pipefail + err_return. Catches unguarded $VAR
# expansions and any module that returns non-zero on a happy path.
smoke-strict:
  #!/usr/bin/env bash
  set -euo pipefail
  out=$(zsh -f -ic '
    setopt nounset pipefail err_return
    export M1ZSH_HOME="$PWD" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1
    source "$M1ZSH_HOME/init.zsh"
    print -- smoke-strict-ok
  ' 2>&1)
  printf '%s\n' "$out"
  printf '%s\n' "$out" | grep -qx 'smoke-strict-ok' \
    || { printf 'smoke-strict: marker missing\n' >&2; exit 1; }
  printf 'smoke-strict: PASS\n'

# Idempotency: source init.zsh twice and prove path/fpath are stable, the
# precmd hook is not duplicated, and no `m1zsh:` warning is emitted on the
# second pass.
smoke-twice:
  #!/usr/bin/env bash
  set -euo pipefail
  out=$(zsh -f -ic '
    export M1ZSH_HOME="$PWD" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1
    source "$M1ZSH_HOME/init.zsh"
    p1=$#path; f1=$#fpath; h1=${#precmd_functions[@]}
    print -r -- "--- second source ---"
    source "$M1ZSH_HOME/init.zsh"
    p2=$#path; f2=$#fpath; h2=${#precmd_functions[@]}
    print -r -- "path=$p1/$p2 fpath=$f1/$f2 precmd=$h1/$h2"
    [[ $p1 -eq $p2 && $f1 -eq $f2 && $h1 -eq $h2 ]] \
      && print -- smoke-twice-ok
  ' 2>&1)
  printf '%s\n' "$out"
  printf '%s\n' "$out" | grep -qx 'smoke-twice-ok' \
    || { printf 'smoke-twice: path/fpath/precmd grew\n' >&2; exit 1; }
  second=$(printf '%s\n' "$out" | sed -n '/--- second source ---/,$p')
  if printf '%s\n' "$second" | grep -qE '^m1zsh: '; then
    printf 'smoke-twice: warnings emitted on re-source\n' >&2
    exit 1
  fi
  printf 'smoke-twice: PASS\n'

# Verify the interactive `setopt`s set by modules survive m1zsh_source.
# Catches the class of bug where a helper wraps `source` in `emulate -L zsh`
# (which silently localises every setopt the module performs).
smoke-setopts:
  #!/usr/bin/env bash
  set -euo pipefail
  out=$(zsh -f -ic '
    export M1ZSH_HOME="$PWD" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1
    source "$M1ZSH_HOME/init.zsh"
    fails=0
    for opt in prompt_subst share_history extended_glob \
               interactive_comments hist_ignore_all_dups; do
      if ! [[ -o $opt ]]; then
        print -u2 -- "FAIL: setopt $opt not active after load"
        fails=$((fails + 1))
      fi
    done
    (( fails == 0 )) && print -- smoke-setopts-ok
  ' 2>&1)
  printf '%s\n' "$out"
  printf '%s\n' "$out" | grep -qx 'smoke-setopts-ok' \
    || { printf 'smoke-setopts: option regression detected\n' >&2; exit 1; }
  printf 'smoke-setopts: PASS\n'

prek-check:
  @if command -v prek >/dev/null 2>&1; then prek run --all-files; else printf 'prek not installed; skipping\n' >&2; fi

# Run the health check in a fresh interactive zsh. Use `just doctor -- --json`
# to forward flags. Exit code mirrors m1zsh_doctor (0 ok, 1 err, 2 warn).
doctor *args:
  @zsh -ic 'export M1ZSH_HOME="$PWD"; source "$M1ZSH_HOME/init.zsh"; m1zsh_doctor {{args}}'

# Smoke test for the doctor subsystem: every mode (text/json/quiet) must
# produce sensible output without leaking absolute home paths.
smoke-doctor:
  @scripts/check-doctor.bash

hook-install:
  @prek install --prepare-hooks --hook-type pre-commit --hook-type pre-push --hook-type commit-msg

fmt:
  @if command -v shfmt >/dev/null 2>&1; then shfmt -w -i 2 -ci -sr scripts/*.bash; else printf 'shfmt not installed; skipping\n' >&2; fi

lint-scripts:
  @shellcheck -x scripts/*.bash

git-users:
  @git log --format='%an <%ae>' | sort -u

release-audit: check git-users
  @printf 'release audit complete\n'
