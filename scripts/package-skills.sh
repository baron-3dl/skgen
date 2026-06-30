#!/usr/bin/env bash
# Generate the Claude Code plugin payload (skills/) from the repo's source of truth.
# The repo root (SKILL.md, FORMAT.md, seed/, examples/) is canonical; skills/ is the
# packaged, installable form the plugin marketplace serves. Re-run after changing a
# source skill, and on every release.
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf skills
mkdir -p skills/skillc/seed

# The builder, as a self-contained skill: its SKILL.md references FORMAT.md and seed/,
# so they travel beside it.
cp SKILL.md                  skills/skillc/SKILL.md
cp FORMAT.md                 skills/skillc/FORMAT.md
cp seed/builder.skill.md     skills/skillc/seed/builder.skill.md
cp seed/rebuild.skill.md     skills/skillc/seed/rebuild.skill.md

# The self-building example skills, each as one installable skill.
for ex in voice explain-plainly commit-message; do
  mkdir -p "skills/$ex"
  cp "examples/$ex.selfbuild.SKILL.md" "skills/$ex/SKILL.md"
done

echo "packaged skills/ from source ($(find skills -name SKILL.md | wc -l | tr -d ' ') skills)"
