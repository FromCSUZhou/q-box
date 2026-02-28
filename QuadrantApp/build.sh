#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="Q Box"
APP_DIR="${APP_NAME}.app"
EXEC_NAME="QuadrantApp"

echo "Building ${APP_NAME}..."
swift build -c release 2>&1

EXEC_PATH=".build/release/${EXEC_NAME}"

if [ ! -f "$EXEC_PATH" ]; then
    echo "Build failed: executable not found at ${EXEC_PATH}"
    exit 1
fi

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "$EXEC_PATH" "${APP_DIR}/Contents/MacOS/${EXEC_NAME}"
cp Info.plist "${APP_DIR}/Contents/Info.plist"

# Copy icon if exists
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

echo ""
echo "Build complete: ${APP_DIR}"
echo ""
echo "Usage:"
echo "  Run directly:     open \"${APP_DIR}\""
echo "  Install to Apps:  cp -r \"${APP_DIR}\" /Applications/"
echo ""
