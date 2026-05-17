set shell := ["bash", "-uc"]

_default:
  @just --list

check: zsh-syntax secrets smoke prek-check

zsh-syntax:
  @scripts/check-zsh.bash

secrets:
  @scripts/scan-secrets.bash

smoke:
  @zsh -f -ic 'export M1ZSH_HOME="$PWD" M1ZSH_SKIP_ZI=1 M1ZSH_DISABLE_TOOL_ADAPTERS=1; source "$M1ZSH_HOME/init.zsh"; print -- m1zsh-smoke-ok'

prek-check:
  @if command -v prek >/dev/null 2>&1; then prek run --all-files; else printf 'prek not installed; skipping\n' >&2; fi

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
