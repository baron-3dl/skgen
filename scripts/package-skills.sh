#!/usr/bin/env bash
# Generate the Claude Code plugin payload (plugins/) from the repo's source of truth.
# Two plugins, kept separate on purpose:
#   skillc          - the builder (the tool)
#   skillc-examples - worked self-building example skills (the demos)
# The repo root (SKILL.md, FORMAT.md, seed/) and examples/ are canonical; plugins/ is
# the packaged, installable form. Re-run after changing a source skill, and on release.
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf plugins

# --- plugin: skillc (the builder) ---
mkdir -p plugins/skillc/.claude-plugin plugins/skillc/skills/skillc/seed
cat > plugins/skillc/.claude-plugin/plugin.json <<'JSON'
{
  "name": "skillc",
  "description": "The builder: package a working skill into one self-building file that rebuilds and tests itself on whoever receives it."
}
JSON
cp SKILL.md               plugins/skillc/skills/skillc/SKILL.md
cp FORMAT.md              plugins/skillc/skills/skillc/FORMAT.md
cp seed/builder.skill.md  plugins/skillc/skills/skillc/seed/builder.skill.md
cp seed/rebuild.skill.md  plugins/skillc/skills/skillc/seed/rebuild.skill.md

# --- plugin: skillc-examples (the demos) ---
mkdir -p plugins/skillc-examples/.claude-plugin
cat > plugins/skillc-examples/.claude-plugin/plugin.json <<'JSON'
{
  "name": "skillc-examples",
  "description": "Worked self-building example skills built and tested with skillc: voice, explain-plainly, commit-message."
}
JSON
for ex in voice explain-plainly commit-message; do
  mkdir -p "plugins/skillc-examples/skills/$ex"
  cp "examples/$ex.selfbuild.SKILL.md" "plugins/skillc-examples/skills/$ex/SKILL.md"
done

echo "packaged plugins/ from source"
find plugins -name SKILL.md | sort | sed 's/^/  /'
