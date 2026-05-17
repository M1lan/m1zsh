# AGENTS.md — m1zsh contributor contract

m1zsh is a public, Zi-based Zsh configuration project. Keep it modular,
portable, and safe to publish.

## Non-negotiables

- Never commit secrets, tokens, private hostnames, private account names, OAuth
  material, shell history, transcripts, or machine-local absolute paths.
- Keep personal config outside the repo. Use the ignored overlay loaded by
  `modules/90-personal.zsh`.
- Do not vendor private generated files. Generated completions need provenance
  and regeneration notes.
- Prefer Zi-managed plugins/snippets and small modules over monolithic `.zshrc`
  edits.
- Keep `.zshenv` minimal: no prompt, widgets, aliases, completions, or network
  calls.
- `CLAUDE.md` must contain only `@AGENTS.md`.

## Project center

- `Justfile` is the development command surface.
- `README.md` is the user-facing entry point.
- `AGENTS.md` is the agent/contributor policy.

## Required verification before completion

Run:

```sh
just check
```

If `prek` is installed, also run:

```sh
prek run --all-files
```

## Commit protocol

Use Lore-style commits:

```text
<why this change was made>

Confidence: high|medium|low
Scope-risk: narrow|moderate|broad
Tested: <commands run>
Not-tested: <known gaps>
```
