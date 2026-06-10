# Release checklist

The first public push (`v0.1.0`) is done; the repo lives at
`git@github.com:M1lan/m1zsh.git`. Run through this before tagging each release:

- [ ] Run `just release-audit`.
- [ ] Confirm `git log --format='%an <%ae>' | sort -u` contains only the
      expected authors.
- [ ] Confirm `git remote -v` points to `git@github.com:M1lan/m1zsh.git`.
- [ ] Review changed files for private paths, histories, accounts, and tokens.
- [ ] Bump `VERSION` and add release notes under `docs/`.
- [ ] Tag the release only after a clean fresh-clone smoke test.
