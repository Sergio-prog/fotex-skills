# fotex-skills

Personal skills and a portable terminal workflow for Claude Code on Linux VPS hosts.

## VPS setup

Open the package selector with one command:

```sh
curl -LsSf https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main/install.sh | sh
```

Use Up/Down to move, Space to toggle, and Enter to install. All packages start selected; press N to clear them. The choices are Micro/tmux/Ghostty terminfo, Claude Code, Codex, OpenCode, molt, and chainq. Codex and OpenCode also install Node.js when needed.

For an unattended host, choose packages explicitly:

```sh
curl -LsSf https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main/install.sh | sh -s -- --only=micro,claude
```

Use `--all` to install every choice without a menu. Without a terminal, the installer requires `--all` or `--only=...`.

The available packages include:

- Micro 2.0.15 with the checked-in settings, terminal clipboard support, and `Ctrl + mouse wheel` horizontal scrolling
- the `xterm-ghostty` terminfo entry and tmux
- Claude Code, Codex, OpenCode, molt, Node.js 24 LTS, Bun, GitHub CLI, jq, and chainq
- the portable Claude Code settings, global instructions, this skill plugin, and the Matt Pocock skills plugin

The installer does not copy authentication, API keys, MCP servers, project sessions, histories, telemetry, caches, or machine-local hooks. Run `claude` and `gh auth login` once on each new host.
Sign in to Codex and OpenCode separately if you use them. `molt harness backup` is a private full backup, not the source for this repository: it includes Claude state and per-project memory. The repo export uses `molt harness --json` to find installed tools and copies only allowlisted settings and instructions.

Install only the terminal workflow:

```sh
curl -LsSf https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main/ghostty-install.sh | sh
```

Install only the Claude Code workflow:

```sh
curl -LsSf https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main/claude-install.sh | sh
```

Install Codex, OpenCode, molt, and their portable instructions after Node.js is available:

```sh
curl -LsSf https://raw.githubusercontent.com/Sergio-prog/fotex-skills/main/harness-install.sh | sh
```

Existing settings and instruction files are backed up before replacement. Running an installer again updates the managed files without duplicating shell configuration.

## Refresh from this Mac

Update the checked-in snapshot before committing:

```sh
scripts/export-workflow.sh
```

The export requires `molt`, `jq`, `rsync`, and Python 3 on the Mac. It copies the selected skills listed in [`config/claude/export-skills.txt`](./config/claude/export-skills.txt). It creates a portable Claude settings file instead of copying `~/.claude.json` or other runtime state.
It also exports the portable Codex preferences and global instructions, plus OpenCode global instructions. It excludes memories, sessions, per-project trust settings, MCP state, credentials, and OpenCode's machine-specific config path. Review the diff before committing.

## Claude cloud sessions

Cloud sessions clone the target GitHub repository. They do not inherit this Mac's `~/.claude/CLAUDE.md`, user skills, or installed plugins. To put the portable instructions and selected skills in a project:

```sh
scripts/prepare-cloud-repo.sh /path/to/project
```

Review and commit those files in the target project, then push before starting a cloud session. The script stops if that project already has `.claude/CLAUDE.md` or a skill with the same name. It does not copy memories. Add concise, project-specific context to the target project's `CLAUDE.md` if you want it in cloud sessions. Claude cloud environments also support setup scripts for CLI tools, but the VPS installer is designed for a personal Linux host and installs more than a cloud session normally needs.
`CLAUDE.md` is Claude's editable instruction file, not the provider's system prompt. The latter cannot be exported by molt or this repository.

For local skill development, link every repository skill into Claude Code and the shared agent directory:

```sh
scripts/link-skills.sh
```

## Skills

- [babysit-git](./skills/babysit-git/SKILL.md) - watch GitHub Actions after a push or PR and act on failures
- [chainq](./skills/chainq/SKILL.md) - query live crypto and onchain data
- [deslop](./skills/deslop/SKILL.md) - remove low-quality generated code from a diff
- [frontend-design](./skills/frontend-design/SKILL.md) - design distinctive frontend interfaces
- [impeccable](./skills/impeccable/SKILL.md) - audit and improve frontend design and UX
- [improve](./skills/improve/SKILL.md) - produce implementation plans from a read-only codebase audit
- [setup-pre-commit](./skills/setup-pre-commit/SKILL.md) - configure Husky and lint-staged checks
- [unslop](./skills/unslop/SKILL.md) - remove common AI writing patterns
