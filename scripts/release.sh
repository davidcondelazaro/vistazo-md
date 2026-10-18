#!/bin/zsh
# Compila una versión Release universal (Apple Silicon + Intel) y la empaqueta en dist/.
# La app va firmada ad-hoc (sin cuenta de Apple Developer), no notarizada.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Vistazo MD.app"
VERSION=$(awk -F'"' '/MARKETING_VERSION/ {print $2; exit}' project.yml)

command -v xcodegen >/dev/null && xcodegen generate --quiet
rm -rf build/Release-dist
xcodebuild -project VistazoMD.xcodeproj -scheme VistazoMD -configuration Release \
  -derivedDataPath build/Release-dist -destination 'generic/platform=macOS' \
  ONLY_ACTIVE_ARCH=NO -quiet build

BUILT="build/Release-dist/Build/Products/Release/$APP_NAME"
# Que el sistema no registre esta copia como extensión de Quick Look.
pluginkit -r "$BUILT/Contents/PlugIns/MarkdownPreview.appex" 2>/dev/null || true

mkdir -p dist
ZIP="dist/VistazoMD-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$BUILT" "$ZIP"
rm -rf build/Release-dist

echo "Creado $ZIP"
