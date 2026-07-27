#!/usr/bin/env bash
# Regenerate ios/Flutter/Generated.xcconfig from pubspec.yaml after git pull.
# Xcode Archive reads FLUTTER_BUILD_NUMBER from that generated file (gitignored),
# so a pull that updates pubspec alone can still Archive the previous build number.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! grep -E '^version:' pubspec.yaml | grep -Eq 'version:[[:space:]]*([0-9.]+)\+([0-9]+)'; then
  echo "Could not parse version from pubspec.yaml" >&2
  exit 1
fi

VERSION_LINE="$(grep -E '^version:' pubspec.yaml | head -1)"
NAME="${VERSION_LINE#version:}"
NAME="$(echo "$NAME" | tr -d '[:space:]')"
BUILD_NAME="${NAME%%+*}"
BUILD_NUMBER="${NAME##*+}"

echo "Refreshing iOS build numbers from pubspec: $BUILD_NAME+$BUILD_NUMBER"
flutter pub get
flutter build ios --config-only --release --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"

CONFIG="$ROOT/ios/Flutter/Generated.xcconfig"
if [[ ! -f "$CONFIG" ]]; then
  echo "Missing $CONFIG after flutter build ios --config-only" >&2
  exit 1
fi

echo "--- $CONFIG ---"
grep -E 'FLUTTER_BUILD_(NAME|NUMBER)=' "$CONFIG"
echo "OK — Archive only after FLUTTER_BUILD_NUMBER=$BUILD_NUMBER"
