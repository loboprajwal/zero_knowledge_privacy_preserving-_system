#!/bin/bash
set -e

# ==============================================================================
# Build Script for Mopro Native Mobile Bindings (Android & iOS)
# ==============================================================================

echo "=== [1/4] Checking Mopro CLI and Cargo Targets ==="
if command -v mopro &> /dev/null; then
    echo "Found mopro CLI. Building via mopro build..."
    mopro build --config mopro.toml
else
    echo "mopro CLI not found in PATH. Building standard cargo dynamic library..."
    cargo build --release
fi

echo "=== [2/4] Packaging Android Libraries ==="
ANDROID_JNI_DIR="../mobile/android/app/src/main/jniLibs"
mkdir -p "$ANDROID_JNI_DIR/arm64-v8a"
mkdir -p "$ANDROID_JNI_DIR/armeabi-v7a"
mkdir -p "$ANDROID_JNI_DIR/x86_64"

# If compiled via cargo ndk or mopro, copy .so files
if [ -f "target/release/libmopro_bindings.so" ]; then
    cp "target/release/libmopro_bindings.so" "$ANDROID_JNI_DIR/arm64-v8a/"
    echo "Copied libmopro_bindings.so to Android jniLibs"
fi

echo "=== [3/4] Packaging iOS Framework ==="
IOS_FRAMEWORK_DIR="../mobile/ios/Frameworks"
mkdir -p "$IOS_FRAMEWORK_DIR"

if [ -d "MoproBindings.xcframework" ]; then
    cp -R "MoproBindings.xcframework" "$IOS_FRAMEWORK_DIR/"
    echo "Copied MoproBindings.xcframework to iOS Frameworks"
fi

echo "=== [4/4] Mopro Mobile Build Finished ==="
