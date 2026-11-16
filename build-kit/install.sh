#!/usr/bin/env bash
# Home build kit: make both skills available to Claude everywhere.
#
#   ./install.sh          symlink the skills into ~/.claude/skills
#   ./install.sh check    report what is linked, change nothing
#   ./install.sh remove   unlink them again
#
# The skills are SYMLINKED, so editing a SKILL.md here takes effect immediately in
# every project. Re-run only when a skill is added, removed or renamed.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
SKILLS=(build-planner build-takeoff)

case "${1:-install}" in
  check)
    for s in "${SKILLS[@]}"; do
      if [ -L "$DEST/$s" ]; then
        printf '%-16s -> %s\n' "$s" "$(readlink "$DEST/$s")"
      elif [ -e "$DEST/$s" ]; then
        printf '%-16s    NOT A SYMLINK (a real directory is in the way)\n' "$s"
      else
        printf '%-16s    not linked\n' "$s"
      fi
    done
    ;;
  remove)
    for s in "${SKILLS[@]}"; do
      if [ -L "${DEST:?}/${s:?}" ]; then rm "${DEST:?}/${s:?}"; echo "unlinked $s"; fi
    done
    ;;
  install)
    mkdir -p "$DEST"
    for s in "${SKILLS[@]}"; do
      [ -f "$SRC/$s/SKILL.md" ] || { echo "missing $SRC/$s/SKILL.md" >&2; exit 1; }
      if [ -e "$DEST/$s" ] && [ ! -L "$DEST/$s" ]; then
        echo "refusing to replace $DEST/$s: it is a real directory, not a symlink" >&2
        exit 1
      fi
      ln -sfn "$SRC/$s" "$DEST/$s"
      echo "linked $s"
    done
    echo
    echo "Ask Claude to \"plan a garage workbench in 3D\" to pick them up."
    ;;
  *)
    echo "usage: $0 [install|check|remove]" >&2; exit 2;;
esac
