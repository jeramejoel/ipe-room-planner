#!/bin/bash
# Starts a new 3D build planner from the template: a folder with index.html, check.sh,
# a README and a git repo, ready for GitHub Pages.
# Usage: new-planner.sh "Garage Workbench" [~/Documents/dev]
set -eu
title="${1:?Give the build a name, for example: new-planner.sh \"Garage Workbench\"}"
parent="${2:-$HOME/Documents/dev}"
here="$(cd "$(dirname "$0")" && pwd)"
slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//')"
dir="$parent/$slug-planner"
[ -e "$dir" ] && { echo "$dir already exists"; exit 1; }
mkdir -p "$dir"
sed -e "s/id:'alcove-shelf'/id:'$slug'/" -e "s/title:'Alcove Shelf'/title:'$title'/" "$here/build-planner.html" > "$dir/index.html"
cp "$here/check.sh" "$dir/check.sh"
cat > "$dir/README.md" <<EOF
# $title planner

A 3D planner for the $title build: tap a part for its cut, open the cut list for what to buy, and follow the build guide.

- Open \`index.html\` in a browser. No build step.
- Edit only the ITEM block at the top of the first script: dims, stock, controls, presets and \`build()\`.
- Every dimension says where it came from (measured, assumed or chosen). Measure the assumed ones before cutting.
- \`./check.sh\` runs the checks over every preset. Run it before each commit.

Started from the build planner template in the home build kit (\`build-kit/skills/build-planner/template\`), at github.com/jeramejoel/ipe-room-planner.
EOF
cd "$dir" && git init -q && git add -A && git commit -q -m "Start the $title planner from the build planner template"
echo "Made $dir"
echo "Next: edit the ITEM block in index.html, run ./check.sh, then publish:"
echo "  gh repo create $slug-planner --public --source=. --push"
echo "  gh api -X POST repos/{owner}/$slug-planner/pages -f \"source[branch]=main\" -f \"source[path]=/\""
