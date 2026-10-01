#!/usr/bin/env bash
# Decide whether the Overleaf project has a new release to publish.
#
#   find-release.sh <overleaf clone> <RELEASED_FROM file> <force: true|false>
#
# Prints GitHub step outputs: publish=true|false, and when true, commit= (the
# Overleaf commit where RELEASE.txt last changed) and note= (its newest line).
#
# A release is a non-comment line in RELEASE.txt. The project is published as
# it stood at the commit that last changed that file, so edits made after a
# release wait for the next one.
set -euo pipefail
repo=$1; state=$2; force=${3:-false}

say() { echo "$*" >&2; }

if ! git -C "$repo" cat-file -e HEAD:RELEASE.txt 2>/dev/null; then
  say "No RELEASE.txt in the Overleaf project; nothing to publish."
  echo "publish=false"; exit 0
fi

commit=$(git -C "$repo" log -1 --format=%H -- RELEASE.txt)
note=$(git -C "$repo" show "$commit:RELEASE.txt" | grep -vE '^[[:space:]]*(#|$)' | tail -n 1 || true)

if [ -z "$note" ]; then
  say "RELEASE.txt has no release line yet; nothing to publish."
  echo "publish=false"; exit 0
fi

last=$(cat "$state" 2>/dev/null || true)
if [ "$commit" = "$last" ] && [ "$force" != "true" ]; then
  say "Release '$note' (Overleaf $commit) is already published."
  echo "publish=false"; exit 0
fi

say "New release: '$note' (Overleaf $commit)."
echo "publish=true"
echo "commit=$commit"
# keep the note on one line and short enough for a commit subject
echo "note=$(printf '%s' "$note" | tr -d '\r' | cut -c1-120)"
