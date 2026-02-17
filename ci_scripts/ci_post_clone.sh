#!/bin/bash
set -euo pipefail

# Xcode Cloud ci_post_clone — set build number from git commit count.
# This overrides Xcode Cloud's auto-increment so local and CI builds
# produce the same deterministic build number.

PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/Safa.xcodeproj/project.pbxproj"
BUILD_NUMBER=$(git -C "$CI_PRIMARY_REPOSITORY_PATH" rev-list --count HEAD)

if [ -z "$BUILD_NUMBER" ] || [ "$BUILD_NUMBER" = "0" ]; then
    BUILD_NUMBER=1
fi

sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" "$PBXPROJ"

echo "Build number set to $BUILD_NUMBER (git commit count)"
