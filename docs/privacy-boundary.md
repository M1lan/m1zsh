# Privacy boundary

Public repository contents must be safe for a GitHub release.

## Public by default

- Generic PATH defaults guarded by directory existence.
- Zsh options, history behavior, completion styles.
- Zi plugin declarations using public plugin names.
- Small aliases and helpers with no private paths or accounts.
- Tool adapters that only source documented local init files if present.

## Local-only

- Tokens, webhooks, OAuth credentials, private keys.
- Private/work account names and account-specific config homes.
- Prompt/history transcripts and AI conversation history.
- Machine-specific absolute paths.
- Window-manager rules, brand-specific terminal launchers, and local scripts.
- Generated files that reveal installed private tools or history.

## Enforcement

- `.gitignore` excludes common secret and overlay paths.
- `scripts/scan-secrets.bash` blocks common token/key/private-path patterns.
- `modules/90-personal.zsh` loads ignored local overlays.
