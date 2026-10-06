#!/bin/bash

# Build the Swift framework for physical iOS devices and both simulator
# architectures. The historical filename is retained because existing notes
# and developer workflows refer to it, but the output is a modern XCFramework.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
PROJECT_NAME="WidgetCenterProxy"
PROJECT_PATH="$SCRIPT_DIR/$PROJECT_NAME/$PROJECT_NAME.xcodeproj"
OUTPUT_PATH="$SCRIPT_DIR/VendorFrameworks/$PROJECT_NAME.xcframework"
BUILD_ROOT="$(mktemp -d /tmp/WidgetCenterProxy.XXXXXX)"
DEVICE_ARCHIVE="$BUILD_ROOT/WidgetCenterProxy-iOS.xcarchive"
SIMULATOR_ARCHIVE="$BUILD_ROOT/WidgetCenterProxy-Simulator.xcarchive"
STAGED_OUTPUT="$BUILD_ROOT/$PROJECT_NAME.xcframework"

cleanup() {
    rm -rf "$BUILD_ROOT"
}
trap cleanup EXIT

echo "Building $PROJECT_NAME for iOS devices"
xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$PROJECT_NAME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$DEVICE_ARCHIVE" \
    SKIP_INSTALL=NO \
    IPHONEOS_DEPLOYMENT_TARGET=16.0 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
    CODE_SIGNING_ALLOWED=NO

echo "Building $PROJECT_NAME for iOS Simulator"
xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$PROJECT_NAME" \
    -configuration Release \
    -destination 'generic/platform=iOS Simulator' \
    -archivePath "$SIMULATOR_ARCHIVE" \
    SKIP_INSTALL=NO \
    IPHONEOS_DEPLOYMENT_TARGET=16.0 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
    CODE_SIGNING_ALLOWED=NO

echo "Creating $PROJECT_NAME.xcframework"
xcodebuild -create-xcframework \
    -framework "$DEVICE_ARCHIVE/Products/Library/Frameworks/$PROJECT_NAME.framework" \
    -debug-symbols "$DEVICE_ARCHIVE/dSYMs/$PROJECT_NAME.framework.dSYM" \
    -framework "$SIMULATOR_ARCHIVE/Products/Library/Frameworks/$PROJECT_NAME.framework" \
    -debug-symbols "$SIMULATOR_ARCHIVE/dSYMs/$PROJECT_NAME.framework.dSYM" \
    -output "$STAGED_OUTPUT"

# Only replace the checked-in framework after both archives and XCFramework
# creation have succeeded.
rm -rf "$OUTPUT_PATH"
mv "$STAGED_OUTPUT" "$OUTPUT_PATH"

echo "Updated $OUTPUT_PATH"
