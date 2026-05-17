# Release checklist

Before the first public GitHub push:

- [ ] Run `just release-audit`.
- [ ] Confirm `git log --format='%an <%ae>' | sort -u` contains only m1lan.
- [ ] Confirm `git remote -v` points to `git@github.com:m1lan/m1zsh.git`.
- [ ] Review every file for private paths, histories, accounts, and tokens.
- [ ] Choose and add a license.
- [ ] Decide whether generated completions should be vendored or regenerated.
- [ ] Tag the first release only after a clean fresh-clone smoke test.
