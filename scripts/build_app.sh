#!/usr/bin/env bash
# Empaqueta UPTCBot.app a partir del último build de xcodebuild (Debug)
# + modelo + icono. Usa hardlinks para no duplicar 3.4 GB.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="UPTCBotApp"
APP_NAME="UPTCBot"
BUNDLE_ID="co.edu.uptc.uptcbot"
VERSION="1.0.0"
DERIVED="$PROJECT_DIR/.build-xcode"
DIST="$PROJECT_DIR/dist"
APP_DIR="$DIST/$APP_NAME.app"

cd "$PROJECT_DIR"

echo "==> [1/6] Verificando build existente..."
BUILD_DIR="$DERIVED/Build/Products/Debug"
if [[ ! -f "$BUILD_DIR/$SCHEME" ]]; then
    echo "    No hay build Debug — compilando ahora..."
    xcodebuild -scheme "$SCHEME" \
        -destination 'platform=macOS,arch=arm64' \
        -derivedDataPath "$DERIVED" \
        -skipMacroValidation \
        -quiet \
        build
fi
echo "    Build dir: $BUILD_DIR"

echo "==> [2/6] Limpiando dist anterior..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "==> [3/6] Copiando binario (MacOS/) y resource bundles (Resources/)..."
# El binario va directo como UPTCBot (CFBundleExecutable). No usamos wrapper
# bash porque macOS Launch Services no maneja bien shell scripts como
# entry point de un .app.
cp "$BUILD_DIR/$SCHEME" "$APP_DIR/Contents/MacOS/${APP_NAME}"
chmod +x "$APP_DIR/Contents/MacOS/${APP_NAME}"
# Los bundles van a Resources/, NO a MacOS/ — SwiftPM resource accessor
# busca en Bundle.main.resourceURL (= Contents/Resources/) cuando el
# binario corre dentro de un .app. Si los pones en MacOS/, MLX no
# encuentra default.metallib y la app se cierra al arrancar.
for bundle in "$BUILD_DIR"/*.bundle; do
    [[ -e "$bundle" ]] || continue
    cp -R "$bundle" "$APP_DIR/Contents/Resources/"
done

echo "==> [4/6] Hardlinking Model/ (sin duplicar 3.4 GB)..."
cp -aRl "$PROJECT_DIR/Model" "$APP_DIR/Contents/Resources/Model"

echo "==> [5/6] Icono + Info.plist..."
cp "$PROJECT_DIR/build/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>es</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>UPTCBot</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.education</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>UPTCBot — Asistente local UPTC con Gemma 4 + RAG.</string>
</dict>
</plist>
PLIST

echo "==> [6/6] Finalizando..."
# Ya no hay wrapper bash. ModelService.resolveModelDirectory() auto-detecta
# Model/ desde Bundle.main.resourceURL cuando corre dentro del .app.
touch "$APP_DIR"

echo ""
echo "✓ App empacada en: $APP_DIR"
du -sh "$APP_DIR" 2>/dev/null || true
