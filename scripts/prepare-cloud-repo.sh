#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
TARGET=${1:?usage: scripts/prepare-cloud-repo.sh /path/to/project}

[[ -d $TARGET/.git || -f $TARGET/.git ]] || {
  printf 'target must be a Git repository: %s\n' "$TARGET" >&2
  exit 1
}
TARGET=$(cd "$TARGET" && pwd)
[[ $TARGET != "$REPO" ]] || {
  printf 'choose a project repository, not fotex-skills\n' >&2
  exit 1
}
[[ ! -e $TARGET/.claude/CLAUDE.md ]] || {
  printf 'existing .claude/CLAUDE.md needs manual review: %s\n' "$TARGET" >&2
  exit 1
}

while IFS= read -r skill_name; do
  [[ -z $skill_name || $skill_name == \#* ]] && continue
  [[ ! -e $TARGET/.claude/skills/$skill_name ]] || {
    printf 'existing project skill needs manual review: %s\n' "$skill_name" >&2
    exit 1
  }
done <"$REPO/config/claude/export-skills.txt"

mkdir -p "$TARGET/.claude/skills"
cp "$REPO/config/claude/CLAUDE.md" "$TARGET/.claude/CLAUDE.md"
while IFS= read -r skill_name; do
  [[ -z $skill_name || $skill_name == \#* ]] && continue
  cp -R "$REPO/skills/$skill_name" "$TARGET/.claude/skills/$skill_name"
done <"$REPO/config/claude/export-skills.txt"

printf 'Copied portable instructions and selected skills to %s/.claude\n' "$TARGET"
printf 'Review these files and the target repository diff before committing and pushing.\n'
