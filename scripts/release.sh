#!/usr/bin/env bash
# =============================================================================
# scripts/release.sh — Bump version, tag, and push for CI release
# =============================================================================
# Usage:
#   ./scripts/release.sh patch    # 2.0.0 → 2.0.1
#   ./scripts/release.sh minor    # 2.0.0 → 2.1.0
#   ./scripts/release.sh major    # 2.0.0 → 3.0.0
#
# What it does:
#   1. Bumps the version in pubspec.yaml
#   2. Commits the bump
#   3. Creates an annotated git tag  (e.g. v2.0.1)
#   4. Pushes the commit and tag to origin
#   5. GitHub Actions sees the tag push and builds the release
# =============================================================================

set -euo pipefail

# ── Validate argument ───────────────────────────────────────────────────────
BUMP_TYPE="${1:-}"
if [[ "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
  echo "Usage: $0 {patch|minor|major}"
  exit 1
fi

# ── Extract current version from pubspec.yaml ───────────────────────────────
# pubspec.yaml has a line: version: X.Y.Z+N
VERSION_LINE=$(grep -E '^version: ' pubspec.yaml)
if [[ -z "$VERSION_LINE" ]]; then
  echo "ERROR: Could not find 'version:' line in pubspec.yaml"
  exit 1
fi

# Strip the "version: " prefix and the trailing +N (build number)
FULL_VERSION=$(echo "$VERSION_LINE" | sed 's/^version: //' | tr -d '[:space:]')
SEMVER=$(echo "$FULL_VERSION" | cut -d'+' -f1)
BUILD_NUM=$(echo "$FULL_VERSION" | cut -d'+' -f2 -s || echo "1")

IFS='.' read -r MAJOR MINOR PATCH <<< "$SEMVER"

# ── Bump ────────────────────────────────────────────────────────────────────
case "$BUMP_TYPE" in
  patch)
    PATCH=$((PATCH + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
esac

NEW_SEMVER="${MAJOR}.${MINOR}.${PATCH}"
NEW_BUILD=$((BUILD_NUM + 1))
NEW_VERSION="${NEW_SEMVER}+${NEW_BUILD}"

echo "🔖 Bumping: $SEMVER → $NEW_SEMVER"

# ── Update pubspec.yaml ─────────────────────────────────────────────────────
# Use sed to replace the version line (works on macOS and Linux)
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
else
  sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
fi

echo "   pubspec.yaml: version: $NEW_VERSION"

# ── Commit & Tag ────────────────────────────────────────────────────────────
TAG="v${NEW_SEMVER}"

git add pubspec.yaml
git commit -m "chore: bump version to $NEW_SEMVER"
git tag -a "$TAG" -m "Release $TAG"

echo ""
echo "✅ Tagged: $TAG"
echo ""
echo "🚀 Run the following to trigger the CI build:"
echo "   git push origin main --tags"
echo ""
echo "Or push the current branch:"
echo "   git push origin HEAD --tags"
