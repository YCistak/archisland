# Contributing to ArchIsland

Thanks for helping improve ArchIsland. Bug reports, small fixes and focused
feature proposals are welcome. By participating you agree to follow the
[Code of Conduct](CODE_OF_CONDUCT.md). Project decisions are described in
[GOVERNANCE.md](GOVERNANCE.md); security issues go through
[SECURITY.md](SECURITY.md), not public issues.

## Project layout

Island runs inside a Quickshell shell, a copy of which is bundled under `core/`.

- `Island.qml`, `components/`, `services/`, `views/`: the Dynamic Island UI.
- `bin/island`: the bash CLI (`island restart`, `island demo`, ...).
- `scripts/`, `hooks/`: helper scripts and agent hooks.
- `install.sh`: installer. `companion/`: the separate notifications service.
- `core/`: vendored third-party shell (see
  [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)). Avoid editing it unless the
  change is necessary for ArchIsland.

The plugin IDs (`guilhermerisu.island`, `guilhermerisu.notifications`) are
inherited from the original project and used by `install.sh`, `bin/island`, the
QML IPC target and the companion scripts. Do not rename them without updating
all of those together.

## Development setup

1. Fork and clone the repository.
2. Run `./install.sh` to install into your user directories. Set
   `ARCHISLAND_PATH` to use a different core directory.
3. After editing QML, run `island restart` to reload the shell.
4. Use `island demo [scenario]` to watch animations and states from a terminal.

Do not edit ArchIsland's packaged files under `/usr/share/archisland/`. Preserve
user settings: when editing `shell.json` or menu overrides, keep unrelated
entries intact and provide a clear removal path.

## Branches

Create a topic branch from `main`, named by change type:
`feat/short-description`, `fix/short-description`, `docs/...`, `refactor/...`,
`ci/...`, `chore/...`.

## Commits and pull requests

We use [Conventional Commits](https://www.conventionalcommits.org/) for commit
messages and PR titles. Pull requests are squash-merged, so the PR title becomes
the commit on `main` and drives the changelog.

Format: `type(scope): description`

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
`build`, `ci`, `chore`, `revert`.

Scopes match the `area:` labels: `island`, `live-activities`, `launcher`,
`settings`, `install`, `core`. Example: `fix(launcher): keep selection after filtering`.

Breaking changes use `!` (`feat(settings)!: ...`) or a `BREAKING CHANGE:` footer.

### Developer Certificate of Origin (DCO)

Every commit must be signed off, certifying that you wrote the change or have the
right to submit it under the project's license
(<https://developercertificate.org/>):

```sh
git commit -s -m "fix(island): correct collapse timing"
```

This adds a `Signed-off-by: Your Name <you@example.com>` line that must match the
commit author. Forgot? Use `git commit --amend -s` or
`git rebase --signoff origin/main`. The `DCO` check enforces this.

### English only

All code, comments, identifiers, documentation, commit messages, PR titles and PR
descriptions must be in English. The `English only` check rejects added lines
that contain non-English (Turkish-specific) characters outside `core/`.

## Code style

### QML

- 4-space indentation.
- No hardcoded animation durations. Use the Theme motion tokens
  (`Theme.motionDuration("...")` in `services/Theme.qml`) so users' motion
  preferences apply everywhere.
- Keep IDs and entry points consistent with the QML and shell commands that
  refer to them.

### Shell

- Bash only, with `set -euo pipefail` in new scripts.
- Code must be `shellcheck` clean. If you must disable a check, add a
  `# shellcheck disable=SCxxxx` comment with the reason.
- Never use broad `pkill`/`killall` patterns; target exact PIDs or exact names.

## Checking your work

```sh
shellcheck bin/island install.sh scripts/*.sh hooks/*.sh
qmllint $(git ls-files '*.qml' ':!core/**')
git diff --check
```

For visual changes, check the affected views in a running session and include a
screenshot or short recording in the PR. For setup or removal changes, test a
fresh install, a repeat run and `companion/uninstall.sh --dry-run`, and confirm
unrelated user configuration survives. Do not run destructive checks against a
session with state you cannot restore. Never include credentials, notification
history or other personal state in fixtures, logs or screenshots.

## Pull request checklist

- Conventional Commits title; focused change; linked issue if any.
- All commits signed off.
- English only.
- `shellcheck` and `qmllint` pass.
- No hardcoded durations.
- Describe what changed, how you tested it and known limitations.
- AI assistance disclosed.

## AI-assisted contributions

AI tools are allowed. You must disclose AI assistance in the PR description, and
you must understand and have tested every line you submit. The sign-off (DCO) is
made by the human contributor, never by a tool; do not submit code you cannot
explain.
