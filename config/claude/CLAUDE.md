- try to avoid using comments. based on clean code rules they shouldn't be used cuz code should be self explainiable and they could be deprecated in future
- use conventional standarts for commits, branches, PRs
- be concise and clear
- use the `gh` CLI for GitHub PR work (create, view, check status)
- never create a PR without my explicit permission. when I do ask, create a PR with a conventional title and a short description, then open it in the browser (`gh pr view --web`)
- when I told you to describe something in docs as .md file, do that concisely, without useless or obvious information.
- usually do not run a dev server
- never run migrations, bulk writes, resets, or any other data mutation against ANY database (prod, dev, or local) without my explicit permission — read-only queries are fine. if verification needs a write or a migration run, describe it and let me trigger it

## Worktrees when another agent is active
- when another agent is working (I say so, or I have a dirty tree with unrelated in-progress work), do NOT switch branches or edit in the shared checkout — it would disrupt them and drag their uncommitted changes onto my branch
- instead isolate in a separate git worktree branched from the right base (usually `origin/main`): `git worktree add -b <conventional-branch> ../<repo>-<slug> origin/main`
- a fresh worktree is only tracked files — it has neither deps nor gitignored runtime files. two setup steps make it actually runnable:
  1. deps: run `pnpm install` in the worktree (fast — pnpm hard-links from the global store, negligible extra disk). do NOT symlink `node_modules` to the main checkout — pnpm follows the symlink and will try to wipe/reinstall the main one
  2. gitignored runtime files (`.env`, `.env.*`, local `config/*`, secrets): symlink each from the main checkout, e.g. `ln -sf <main>/.env .env`. discover what's needed with `git -C <main> status --ignored --short | grep '^!!'` (skip `node_modules`/`dist`/`build`/`coverage`/`.git`/`.DS_Store`/`.claude`). single-file symlinks are safe (no package-manager wipe problem) and keep one source of truth for secrets; they stay gitignored so they never get committed. `mkdir -p` the parent dir first for nested paths like `config/`
- caveat when running two apps at once: they share the symlinked `.env`, so override collision-prone values (PORT, DB name) per worktree at launch rather than editing the shared file
- clean up after the work lands: once merged/pushed, `git worktree remove ../<repo>-<slug>` (and `git branch -d` if the branch is done). don't leave stale worktrees trashing the parent dir
- don't remove a worktree with uncommitted or unpushed work still in it
