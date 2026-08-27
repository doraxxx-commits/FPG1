#!/usr/bin/env bash
set -euo pipefail
flutter doctor -v
flutter pub get
flutter test test/world_long_run_audit_test.dart test/world_long_run_integrity_test.dart test/world_player_lifecycle_integrity_test.dart
