---
name: babysit-git
description: Use after pushing a branch or opening a PR, when the user says "babysit" (e.g. "push the changes, babysit it"), or when the user asks whether a commit/push/PR passed its checks. Watches GitHub Actions and acts on failures.
---

For checking the results of GitHub Actions use the GitHub CLI. Every command below works in a non-interactive shell; `gh run watch` without a run id opens an interactive picker and hangs, so always pass the id.

```bash
# runs for the current branch; can be empty for a few seconds right after a push, retry once
gh run list --branch "$(git branch --show-current)" --limit 3 --json databaseId,name,status,conclusion

# most common: watch a run until it finishes, instead of doing check -> sleep -> check
gh run watch <run-id> --exit-status --compact

# for a PR: watch all checks, stop on the first failure
gh pr checks --watch --fail-fast

# read only the failed steps; --log is huge and floods context
gh run view <run-id> --log-failed
```

If gh is not authenticated, try the harness's/platform's GitHub integration if the user has authenticated there. Otherwise tell the user to run `gh auth login`.
Sometimes GitHub rate limits you. The watch commands above already poll, so wait for them instead of polling manually.

## When a job fails

Tell the user and propose a fix when:

- the failure is caused by the workflow YAML itself (syntax, wrong action version, missing secret), or
- the job does important work, like deploying a new release to a server.

Before reporting, check whether the same job was already red on main before this push:

```bash
gh run list --workflow <name> --branch main --limit 5
```

If it was, the user probably already knows. Mention it once and move on; do not repeat it in the same session.

If a job related to linting/formatting/conventional names failed, you are in a PR, and the fix is small: fix it right now without asking. Commit with a conventional message, push to the same PR branch, and watch the new run.

## Done when

- all checks are green, or
- you reported every failed job with the failing step and the relevant lines from `--log-failed`, and either fixed it or proposed a fix.
