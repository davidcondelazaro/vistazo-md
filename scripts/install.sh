#!/bin/zsh
# Compila la app (con su extensión de Quick Look), la instala en ~/Applications y la registra.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Vistazo MD.app"
DEST="$HOME/Applications"

command -v xcodegen >/dev/null && xcodegen generate --quiet
xcodebuild -project VistazoMD.xcodeproj -scheme VistazoMD -configuration Release \
  -derivedDataPath build -quiet build

mkdir -p "$DEST"
rm -rf "$DEST/$APP_NAME"
cp -R "build/Build/Products/Release/$APP_NAME" "$DEST/"

# Xcode registra la copia de build/ al compilar: la olvidamos y la borramos para que
# el sistema use solo la instalada. Después registramos la de ~/Applications.
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
BUILT="build/Build/Products/Release/$APP_NAME"
pluginkit -r "$BUILT/Contents/PlugIns/MarkdownPreview.appex" 2>/dev/null || true
"$LSREGISTER" -u "$BUILT" 2>/dev/null || true
rm -rf "$BUILT"
sleep 2
"$LSREGISTER" -f "$DEST/$APP_NAME"
pluginkit -a "$DEST/$APP_NAME/Contents/PlugIns/MarkdownPreview.appex"
sleep 1
qlmanage -r >/dev/null 2>&1
qlmanage -r cache >/dev/null 2>&1

echo "Instalado en $DEST/$APP_NAME"
pluginkit -m -v -i com.dconde.VistazoMD.MarkdownPreview
