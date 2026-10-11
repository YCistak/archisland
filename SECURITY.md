# Security Policy

## Supported versions

Only the latest release receives security fixes. Please update to the latest
release before reporting an issue.

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Use GitHub private vulnerability reporting instead:
<https://github.com/YCistak/archisland/security/advisories/new>

You can expect an initial response within about 7 days. We will keep you
informed while the issue is investigated and fixed, and credit you in the
release notes if you wish.

## Scope

In scope:

- `install.sh` and the uninstall paths (file operations, privilege use).
- Hooks and scripts that write to user configuration, for example
  `hooks/` and `companion/`, including changes to `shell.json`, Claude/Codex
  settings and other files in the user's home directory.
- The `island` CLI (`bin/island`) and its IPC handling.
- Anything that lets untrusted input (notifications, clipboard, file names,
  network data) execute commands.

Out of scope:

- Vulnerabilities in Hyprland, Quickshell, Qt or other upstream projects
  (report those upstream).
- Issues that require an attacker who already has local code execution as the
  same user.
