#!/usr/bin/env bash
# Usage: upload-thumbnail.sh <png-path> <slug>
# Pushes an approved TUB Connect card thumbnail to TheUncommonBusiness/tub-connect-thumbnails
# (public), checks the link loads, and prints the raw URL (the only stdout line).
set -euo pipefail
PNG="${1:?png path}"; SLUG="${2:?slug (lowercase-with-hyphens)}"
REPO_DIR="$HOME/Documents/tub-connect-thumbnails"
[[ "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "slug must be lowercase-with-hyphens" >&2; exit 1; }
[[ -f "$PNG" ]] || { echo "no such file: $PNG" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh not logged in: run gh auth login" >&2; exit 1; }
[[ -d "$REPO_DIR/.git" ]] || gh repo clone TheUncommonBusiness/tub-connect-thumbnails "$REPO_DIR" >&2
cd "$REPO_DIR"
git pull --rebase -q >&2
cp "$PNG" "thumbnails/$SLUG.png"
git add "thumbnails/$SLUG.png"
if ! git diff --cached --quiet; then
  git commit -qm "Thumbnail: $SLUG" >&2
  git push -q >&2
fi
URL="https://raw.githubusercontent.com/TheUncommonBusiness/tub-connect-thumbnails/main/thumbnails/$SLUG.png"
for i in 1 2 3 4 5; do
  OUT=$(curl -sL -o /dev/null -w "%{http_code} %{content_type}" "$URL")
  [[ "$OUT" == "200 image/png" ]] && { echo "$URL"; exit 0; }
  sleep 3
done
echo "link did not load as image/png (got: $OUT): $URL" >&2; exit 1
