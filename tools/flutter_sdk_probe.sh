#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if command -v flutter >/dev/null 2>&1; then
  echo "Flutter detected: $(flutter --version | head -1)"
  flutter doctor -v || true
  flutter pub get
  flutter analyze
  flutter test
  exit 0
fi

if command -v dart >/dev/null 2>&1; then
  echo "Dart detected: $(dart --version 2>&1)"
  echo "Flutter SDK is missing; Dart-only syntax checks can be run separately."
  exit 2
fi

echo "Flutter SDK unavailable in this environment."
echo "Expected commands when Flutter is installed:"
echo "  flutter pub get"
echo "  flutter analyze"
echo "  flutter test"
exit 3
