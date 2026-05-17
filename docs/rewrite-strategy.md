# m1zsh rewrite strategy

## Source inventory summary

The source config had a large `.zshenv`, a monolithic `.zshrc`, a function
library, generated completions, custom snippets, and a vendored Oh My Zsh tree.
The rewrite keeps the useful architecture and drops private or machine-local
state.

## Module phases

1. `zshenv.zsh` — minimal, non-interactive-safe environment.
2. `modules/00-env.zsh` — interactive defaults and guarded PATH setup.
3. `modules/10-interactive.zsh` — keymap, history, terminal hooks.
4. `modules/20-zi.zsh` — Zi bootstrap only.
5. `modules/30-completion.zsh` — fpath, completion styles, compinit.
6. `modules/40-prompt.zsh` — public fallback prompt.
7. `modules/50-plugins.zsh` — Zi plugin groups and OMZ snippets.
8. `modules/60-aliases.zsh` — safe aliases and tiny helpers.
9. `modules/70-tools.zsh` — public snippets/tool adapters.
10. `modules/90-personal.zsh` — ignored private overlay.

## Porting policy

- Port small, generally useful helpers first.
- Convert generated or machine-owned blocks into optional adapters.
- Do not publish account/history/AI-dispatch/window-manager snippets unless they
  are rewritten as generic templates with no private naming.
- Keep all secrets and credentials in an external overlay.

## Zi policy

- Use `zi light` for normal plugins.
- Use `zi snippet` with `is-snippet` for local files.
- Use `wait` and `lucid` for noncritical post-prompt work.
- Load completion-providing plugins before `compinit`, then run `zicdreplay`.
