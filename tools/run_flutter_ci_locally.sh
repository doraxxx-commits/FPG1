#!/usr/bin/env bash
set -euo pipefail

command -v flutter >/dev/null 2>&1 || { echo 'Flutter SDK not found.'; exit 2; }
command -v java >/dev/null 2>&1 || { echo 'Java not found.'; exit 2; }

flutter --version
dart --version
java -version

if [ ! -d android ]; then
  flutter create --platforms=android --project-name fpg --org com.fpg .
fi

flutter pub get
flutter analyze
flutter test --coverage --reporter expanded
flutter build apk --debug

echo
 echo 'FPG CI LOCAL: PASS'
 echo "APK: build/app/outputs/flutter-apk/app-debug.apk"
