#!/usr/bin/env bash
# Build and install "Terax Local" from branch local/mine (origin/main + personal features).
# Usage: local-install.sh [--update]   (--update: fetch + rebase onto origin/main first)
set -euo pipefail

REPO="$HOME/LocalProjects/terax-ai"
BRANCH="local/mine"
# Feature branches merged into local/mine. Add new ones here.
FEATURES=(feat/new-terminal-home)

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
cd "$REPO"

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "Working tree dirty in $REPO. Commit or stash first." >&2
  exit 1
fi

git switch "$BRANCH"

if [ "${1:-}" = "--update" ]; then
  git fetch origin
  git merge --no-edit origin/main
fi
for b in "${FEATURES[@]}"; do
  git merge --no-edit "$b"
done

pnpm install --frozen-lockfile
pnpm tauri build --bundles app --config '{
  "productName": "Terax Local",
  "identifier": "app.crynta.terax.local",
  "bundle": {"createUpdaterArtifacts": false},
  "plugins": {"updater": {"endpoints": ["http://127.0.0.1:9/latest.json"]}}
}'

APP="src-tauri/target/release/bundle/macos/Terax Local.app"
rm -rf "/Applications/Terax Local.app"
cp -R "$APP" /Applications/
xattr -dr com.apple.quarantine "/Applications/Terax Local.app" || true
echo "Installed /Applications/Terax Local.app"
