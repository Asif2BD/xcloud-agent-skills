#!/usr/bin/env bash
# build.sh — generate claude.ai-compatible Skills from the Claude Code plugin.
#
# The plugin (plugins/xcloud) shares one plugin-level scripts/ + reference/ via
# ${CLAUDE_PLUGIN_ROOT}. claude.ai consumes SELF-CONTAINED skill folders instead,
# so this script, for each capability skill:
#   1. copies the shared wrapper + shared reference INTO the skill folder
#   2. copies the skill's own reference files
#   3. rewrites SKILL.md: strips ${CLAUDE_PLUGIN_ROOT}/ → skill-relative paths,
#      and renames the skill `servers` → `xcloud-servers` (unique on claude.ai)
#   4. zips each folder, ready to drag into claude.ai "Add Skill"
#
# Re-run anytime the plugin changes. Output: dist/claude-app/xcloud-<name>/ + .zip
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/plugins/xcloud"
OUT="$ROOT/dist/claude-app"
SKILLS=(servers sites wordpress ssl account)

echo "Building claude.ai skills from $SRC"
rm -rf "$OUT"/xcloud-* 2>/dev/null || true

for s in "${SKILLS[@]}"; do
  dst="$OUT/xcloud-$s"
  mkdir -p "$dst/scripts" "$dst/reference"

  # shared layer → bundled into each skill (no ${CLAUDE_PLUGIN_ROOT} on claude.ai)
  cp "$SRC/scripts/xcloud.sh"            "$dst/scripts/"
  cp "$SRC/reference/auth.md"            "$dst/reference/"
  cp "$SRC/reference/conventions.md"     "$dst/reference/"

  # skill-local reference files, if any
  if compgen -G "$SRC/skills/$s/reference/*.md" >/dev/null; then
    cp "$SRC/skills/$s/reference/"*.md "$dst/reference/"
  fi

  # SKILL.md: skill-relative paths + unique name
  sed -e 's#\${CLAUDE_PLUGIN_ROOT}/##g' \
      -e "s/^name: ${s}\$/name: xcloud-${s}/" \
      "$SRC/skills/$s/SKILL.md" > "$dst/SKILL.md"

  # zip for upload
  ( cd "$OUT" && rm -f "xcloud-$s.zip" && zip -qr "xcloud-$s.zip" "xcloud-$s" )
  echo "  ✓ xcloud-$s  ($(find "$dst" -type f | wc -l | tr -d ' ') files)"
done

echo "Done → $OUT"
