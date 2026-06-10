# m1zsh

[![ci](https://img.shields.io/github/actions/workflow/status/M1lan/m1zsh/ci.yml?branch=main&label=ci&logo=githubactions&logoColor=white)](https://github.com/M1lan/m1zsh/actions/workflows/ci.yml)

A modular, Zi-based Zsh configuration with turbo loading, small per-phase
modules, and a strict privacy boundary: public defaults ship here; machine-
local and account-specific config lives outside the repo.

## Status

Published at [`M1lan/m1zsh`](https://github.com/M1lan/m1zsh); current release
`v0.1.0`.

## Design goals

- **Zi-first**: Zi plugins and snippets, `wait`/`lucid` turbo loading,
  `zicompinit`/`zicdreplay` where appropriate.
- **Small modules**: one phase of shell startup per file.
- **Portable defaults**: macOS-friendly, guarded against missing tools.
- **Private overlay**: personal config sourced from ignored local files only.
- **Release hygiene**: `just` tasks and `prek` hooks check syntax, commit
  messages, and secret boundaries.

## Layout

```text
.
├── init.zsh                    # interactive entrypoint for .zshrc
├── zshenv.zsh                  # minimal optional .zshenv entrypoint
├── VERSION                     # SemVer string read by m1zsh_doctor
├── bin/m1zsh                   # CLI shim: `m1zsh doctor`, version, home
├── lib/m1zsh.zsh               # shared loader helpers
├── lib/doctor.zsh              # m1zsh_doctor health-check implementation
├── modules/                    # ordered startup phases
├── snippets/                   # reusable public snippets loaded by Zi/source
├── snippets/helpers/           # small zsh helper functions (auto-sourced)
├── completions/                # public generated completions, with provenance
├── templates/                  # copy/symlink examples for users
├── scripts/                    # dev harness checks
├── docs/                       # rewrite strategy, release notes, privacy
├── .github/workflows/          # ci.yml, release.yml
├── Justfile                    # command center
├── prek.toml                   # prek hook config
├── LICENSE                     # MIT
├── AGENTS.md                   # agent/contributor contract
└── CLAUDE.md                   # @AGENTS.md
```

## Quick start

```sh
git clone git@github.com:M1lan/m1zsh.git ~/.config/m1zsh
cd ~/.config/m1zsh
just check
```

Wire your shell files:

```sh
cp templates/zshenv.zsh ~/.zshenv
cp templates/zshrc.zsh ~/.zshrc
```

Install hooks locally:

```sh
just hook-install
```

Verify the installation:

```sh
just doctor                                    # full health report
~/.config/m1zsh/bin/m1zsh doctor               # same, from any shell
~/.config/m1zsh/bin/m1zsh doctor --quiet       # one-line summary
~/.config/m1zsh/bin/m1zsh doctor --json | jq . # machine-readable
```

`m1zsh doctor` exits `0` on success, `1` on error (e.g. insecure `compaudit`
directories), and `2` if only warnings were reported.

## Environment variables

Public knobs read at load time:

- `M1ZSH_HOME` — repo root; auto-detected from `init.zsh` if unset.
- `M1ZSH_SKIP_ZI=1` — bypass the Zi bootstrap module (fallbacks still load).
- `M1ZSH_DISABLE_TOOL_ADAPTERS=1` — skip `modules/70-tools.zsh` snippets.
- `M1ZSH_DISABLE_COMPLETIONS=1` — skip the completion subsystem entirely.
  Useful for embedded shells, CI runners, or environments where `compinit`
  is undesirable.
- `M1ZSH_COMPINIT_INSECURE=1` — keep `compinit -i` (insecure dirs are still
  skipped) but suppress the one-shot `compaudit` warning. Use only when you
  knowingly run on a multi-user host or with shared group ownership of an
  `fpath` dir.
- `ZCACHEDIR` — cache directory; defaults to
  `${XDG_CACHE_HOME:-$HOME/.cache}/zsh`. The compiled completion dump lives
  at `$ZCACHEDIR/.zcompdump(.zwc)` and is rebuilt when older than 24h or
  staler than any `fpath` entry.

## Personal config boundary

Put private settings in one of these ignored locations:

- `$M1ZSH_PERSONAL_FILE`
- `${XDG_CONFIG_HOME:-$HOME/.config}/m1zsh/personal.zsh`
- `${XDG_CONFIG_HOME:-$HOME/.config}/m1zsh/local/*.zsh`

Start from:

```sh
cp templates/personal.zsh ~/.config/m1zsh/personal.zsh
```

Never put tokens, OAuth material, private histories, private account names,
or machine-specific absolute paths in this repository.

## License

m1zsh is released under the MIT License. See [LICENSE](LICENSE).

## Development

```sh
just --list
just check
prek run --all-files
```

Important targets:

- `just check` — full gate: zsh-syntax + secrets + every smoke + prek.
- `just zsh-syntax` — parse every tracked Zsh file with `zsh -n`.
- `just secrets` — scan for common secret and private-path patterns.
- `just smoke` — start a clean interactive Zsh and source `init.zsh`.
- `just smoke-strict` — same, under `nounset`/`pipefail`/`err_return`.
- `just smoke-twice` — re-source `init.zsh` and assert path/fpath/precmd
  are stable (idempotency).
- `just smoke-setopts` — assert interactive `setopt`s survive `m1zsh_source`.
- `just smoke-completion` — compinit ran, `.zcompdump(.zwc)` exist, framework
  fpath passes `compaudit`, and the disable-hatch works.
- `just smoke-doctor` — exercise every doctor output mode.
- `just doctor` — run the `m1zsh_doctor` health report.
- `just hook-install` — install `prek` hooks.
- `just release-audit` — `check` plus the git-author roster.

## Zi notes

m1zsh follows Zi's documented split between plugins and snippets. Local
snippet files are loaded with Zi's `is-snippet` ice where possible; plugin
groups use `wait` and `lucid` for turbo loading. Completion setup keeps
extra fpath entries and `zsh-users/zsh-completions` before `compinit`, then
replays Zi completion definitions.

## Releasing

See `docs/release-checklist.md` before tagging a release.
