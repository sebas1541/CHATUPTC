#!/usr/bin/env bash
# Compila y corre el CLI uptcbot via xcodebuild (necesario para que MLX
# encuentre default.metallib — swift run no compila shaders Metal).
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="uptcbot"
DEST='platform=macOS,arch=arm64'
DERIVED="$PROJECT_DIR/.build-xcode"

cd "$PROJECT_DIR"

echo "==> Compilando con xcodebuild (Metal shaders incluidos)..."
xcodebuild -scheme "$SCHEME" \
    -destination "$DEST" \
    -derivedDataPath "$DERIVED" \
    -skipMacroValidation \
    -quiet \
    build

BUILD_DIR="$DERIVED/Build/Products/Debug"

if [[ ! -f "$BUILD_DIR/$SCHEME" ]]; then
    echo "Error: no encontré el binario en '$BUILD_DIR/$SCHEME'"
    echo "Contenido de $BUILD_DIR:"
    ls -la "$BUILD_DIR" 2>/dev/null || echo "  (directorio no existe)"
    exit 1
fi

echo "==> Ejecutando desde $BUILD_DIR"
echo "==> Modelo: $PROJECT_DIR/Model"
echo ""
cd "$BUILD_DIR"
UPTC_MODEL_PATH="$PROJECT_DIR/Model" exec "./$SCHEME"
