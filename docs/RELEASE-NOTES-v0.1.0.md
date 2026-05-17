# m1zsh v0.1.0 Release Notes

## Overview

m1zsh v0.1.0 is the initial public release of a modular, Zi-first Zsh configuration.
It keeps public defaults in the repository while machine-local paths, accounts, tokens, and personal preferences stay in ignored overlays.

## Highlights

- Ordered startup phases for environment, interactivity, Zi, completions, prompt, plugins, aliases, tools, and personal overlays.
- Zi-first plugin wiring with turbo-loading, completion replay, and guarded fallback behavior when Zi is unavailable.
- Portable defaults for XDG paths, history, prompt behavior, aliases, archive helpers, Git helpers, and common tool adapters.
- Local overlay support through personal files and snippet directories excluded from version control.
- Optional `.zshenv` and `.zshrc` templates for adoption without copying private settings into the public repository.
- Release hygiene via syntax checks, smoke startup checks, hook config, commit-message checks, and secret-boundary scanning.

## Install

1. Clone the repository to `~/.config/m1zsh`.
2. Run `just check` from the repository root.
3. Copy `templates/zshenv.zsh` to `~/.zshenv` and `templates/zshrc.zsh` to `~/.zshrc`.
4. Optionally copy `templates/personal.zsh` to the local personal overlay path.
5. Install Zi separately if you want Zi-managed plugin loading.

## Known-limitations

- This is an initial v0.1.0 release, so defaults are conservative and may change.
- Zi is not vendored or installed automatically.
- Optional tool adapters activate only when their underlying tools are installed.
- Generated completions should be added only when safe to publish and documented with clear regeneration provenance.
- Local overlays are powerful by design; users remain responsible for keeping private content out of version control.

## Acknowledgements

Thanks to the Zi and Zsh plugin ecosystems, the maintainers of the public tools integrated by the adapters, and everyone who values modular, auditable shell configs.
