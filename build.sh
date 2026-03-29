#!/bin/bash
set -e

SDK="$(xcrun --show-sdk-path)"
TARGET="x86_64-apple-macosx14.0"
BUILD_DIR="build"
APP_NAME="VercelDeploys"

SOURCES=(
    VercelDeploys/Models/Deployment.swift
    VercelDeploys/Services/KeychainHelper.swift
    VercelDeploys/Services/VercelAPIClient.swift
    VercelDeploys/ViewModels/AppViewModel.swift
    VercelDeploys/Views/LoginView.swift
    VercelDeploys/Views/DeploymentListView.swift
    VercelDeploys/Views/DeploymentDetailView.swift
    VercelDeploys/Views/ContentView.swift
    VercelDeploys/AppDelegate.swift
    VercelDeploys/VercelDeploysApp.swift
)

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Compiling (this may take a few minutes with SwiftUI)..."
swiftc \
    -sdk "$SDK" \
    -target "$TARGET" \
    -O \
    -whole-module-optimization \
    -parse-as-library \
    -module-name "$APP_NAME" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Security \
    -o "$BUILD_DIR/$APP_NAME" \
    "${SOURCES[@]}"

echo "==> Creating app bundle..."
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS" "$RESOURCES"

cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"
cp VercelDeploys/Info.plist "$CONTENTS/Info.plist"

echo "==> Creating DMG..."
DMG_DIR="$BUILD_DIR/dmg"
mkdir -p "$DMG_DIR"
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -sf /Applications "$DMG_DIR/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$BUILD_DIR/$APP_NAME.dmg"

echo ""
echo "==> Done! DMG at: $(pwd)/$BUILD_DIR/$APP_NAME.dmg"
