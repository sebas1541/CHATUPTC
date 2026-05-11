#!/usr/bin/env bash
# Compila y abre la app SwiftUI UPTCBotApp via xcodebuild
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="UPTCBotApp"
DEST='platform=macOS,arch=arm64'
DERIVED="$PROJECT_DIR/.build-xcode"

cd "$PROJECT_DIR"

echo "==> Compilando con xcodebuild..."
xcodebuild -scheme "$SCHEME" \
    -destination "$DEST" \
    -derivedDataPath "$DERIVED" \
    -skipMacroValidation \
    -quiet \
    build

BUILD_DIR="$DERIVED/Build/Products/Debug"

if [[ ! -f "$BUILD_DIR/$SCHEME" ]]; then
    echo "Error: no encontré el binario en '$BUILD_DIR/$SCHEME'"
    exit 1
fi

echo "==> Abriendo $SCHEME"
echo "==> Modelo: $PROJECT_DIR/Model"
echo ""
cd "$BUILD_DIR"
UPTC_MODEL_PATH="$PROJECT_DIR/Model" exec "./$SCHEME"
