#!/bin/bash
set -e

git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
export PATH="$PATH:$(pwd)/flutter/bin"
export FLUTTER_ROOT="$(pwd)/flutter"

# Allow running as root
export FLUTTER_SUPPRESS_ANALYTICS=1
git config --global --add safe.directory $(pwd)/flutter

flutter config --enable-web --no-analytics
flutter pub get
flutter build web \
  --dart-define=BACKEND_URL=$BACKEND_URL \
  --dart-define=PRODUCTOS_URL=$PRODUCTOS_URL
