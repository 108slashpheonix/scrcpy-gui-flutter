#!/bin/bash
set -e

# Define directories
PROJECT_DIR=$(pwd)
MACOS_DIR="$PROJECT_DIR/macos"

echo "🧹 Cleaning Flutter build..."
flutter clean

echo "🗑️  Removing Pods and Podfile.lock..."
rm -rf "$MACOS_DIR/Pods"
rm -f "$MACOS_DIR/Podfile.lock"

echo "📦 Getting Flutter packages..."
flutter pub get

echo "🥥 Installing CocoaPods..."
cd "$MACOS_DIR"
# Ensure we are using the correct ruby/pod environment if possible, but default to system or user path
pod install

echo "✅ Done! Please follow these steps to build in Xcode:"
echo "1. Open Xcode."
echo "2. Close any open projects."
echo "3. Open '$MACOS_DIR/Runner.xcworkspace' (NOT .xcodeproj)."
echo "4. Select 'Runner' scheme and 'My Mac' destination."
echo "5. Product -> Clean Build Folder."
echo "6. Product -> Build (or Archive)."
