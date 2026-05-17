# m1zsh

A public, modular Zsh configuration built around
[Zi](https://wiki.zshell.dev/) snippets, turbo-loading, and small readable
modules.

The goal is to turn a personal monolithic shell config into a shareable project
with a strict privacy boundary: public defaults live here; machine-local and
account-specific config lives outside the repository.

## Status

Local release-prep rewrite. No GitHub push has been performed.

## Design goals

- **Zi-first**: use Zi plugins, snippets, `wait`/`lucid` turbo loading, and
  `zicompinit`/`zicdreplay` where they fit.
- **Small modules**: each file owns one phase of shell startup.
- **Portable defaults**: macOS-friendly, but guarded so missing tools do not
  break startup.
- **Private overlay**: load personal config from ignored local files only.
- **Release hygiene**: `just` tasks and `prek` hooks check syntax, formatting
  basics, commit messages, and secret boundaries.

## Layout

```text
.
├── init.zsh                    # interactive entrypoint for .zshrc
├── zshenv.zsh                  # minimal optional .zshenv entrypoint
├── lib/m1zsh.zsh               # shared loader helpers
├── modules/                    # ordered startup phases
├── snippets/                   # reusable public snippets loaded by Zi/source
├── completions/                # public generated completions, with provenance
├── templates/                  # copy/symlink examples for users
├── scripts/                    # dev harness checks
├── docs/                       # rewrite strategy and privacy notes
├── Justfile                    # command center
├── prek.toml                   # prek hook config
├── AGENTS.md                   # agent/contributor contract
└── CLAUDE.md                   # @AGENTS.md
```

## Quick start

```sh
git clone git@github.com:m1lan/m1zsh.git ~/.config/m1zsh
cd ~/.config/m1zsh
just check
```

Then wire your shell files:

```sh
cp templates/zshenv.zsh ~/.zshenv
cp templates/zshrc.zsh ~/.zshrc
```

Install hooks locally:

```sh
just hook-install
```

## Personal config boundary

Put private settings in one of these ignored locations:

- `$M1ZSH_PERSONAL_FILE`
- `${XDG_CONFIG_HOME:-$HOME/.config}/m1zsh/personal.zsh`
- `${XDG_CONFIG_HOME:-$HOME/.config}/m1zsh/local/*.zsh`

Start from:

```sh
cp templates/personal.zsh ~/.config/m1zsh/personal.zsh
```

Never put tokens, OAuth material, private histories, private account names, or
machine-specific absolute paths in this repository.

## License

m1zsh is released under the MIT License. See [LICENSE](LICENSE) for details.

## Development

```sh
just --list
just check
prek run --all-files
```

Important targets:

- `just zsh-syntax` — parse every tracked Zsh file with `zsh -n`.
- `just secrets` — scan for common secret and private-path patterns.
- `just smoke` — start a clean interactive Zsh and source `init.zsh`.
- `just hook-install` — install `prek` hooks.

## Zi notes

m1zsh follows Zi's documented split between plugins and snippets. Local snippet
files are loaded with Zi's `is-snippet` ice where possible, while plugin groups
use `wait` and `lucid` for turbo loading. Completion setup keeps extra fpath
entries and `zsh-users/zsh-completions` before `compinit`, then replays Zi
completion definitions.

## Before publishing

See `docs/release-checklist.md`. In particular, choose a license before the
first public push.
