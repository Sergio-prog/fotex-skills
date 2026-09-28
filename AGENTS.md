# fotex-skills

Personal agent skills. One folder per skill under `skills/<name>/SKILL.md`, shipped as a Claude Code plugin via `.claude-plugin/plugin.json`.

## Philosophy

The first draft of every `SKILL.md` is written by the owner. The instructions inside a skill are the owner's judgement about how work should be done, and they stay in the owner's voice. An agent's role around a skill is:

- scaffold the folder, frontmatter, and manifest entries
- give feedback: wrong facts, vague triggers, commands that behave differently in a non-interactive shell, missing completion criteria
- apply the changes the owner agreed to, keeping the owner's wording where it was not the problem
- keep `.claude-plugin/plugin.json` and `README.md` in sync with `skills/`

An agent does not rewrite a skill's substance unprompted. Propose changes in the reply first.

## Conventions

- Every skill in `skills/` is listed in `.claude-plugin/plugin.json` `skills` and in `README.md`, name linked to its `SKILL.md`.
- Frontmatter: `name` matches the folder name. `description` is the trigger pointer: lead with the trigger, one clause per distinct branch, no restating the body. Skills fired only by hand set `disable-model-invocation: true`.
- Run `claude plugin validate . --strict` after touching a manifest.
- `scripts/link-skills.sh` symlinks every skill into `~/.claude/skills` and `~/.agents/skills` for local use. Re-run after adding or renaming a skill.
- `scripts/export-workflow.sh` refreshes the portable Micro, Ghostty, Claude Code, and selected skill snapshot from the current Mac. Never add credentials, MCP state, histories, caches, or machine-local hooks to the snapshot.
- Keep `ghostty-install.sh`, `claude-install.sh`, `harness-install.sh`, and `install.sh` POSIX-compatible because they are executed through `curl | sh`.
