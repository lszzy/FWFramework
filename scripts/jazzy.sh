#! /bin/bash

# Documentation:
# This script generates jazzy docs for CocoaPods Framework.

# Usage:
# jazzy.sh
# e.g. `bash scripts/jazzy.sh`

# Exit immediately if a command exits with non-zero status
set -e

# Use the script folder to refer to other scripts.
FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_PACKAGE_NAME="$FOLDER/package_name.sh"

# Get package name
PACKAGE_NAME=$("$SCRIPT_PACKAGE_NAME") || { echo "Failed to get package name"; exit 1; }
LIB_PATH="docs/$PACKAGE_NAME/"

# Create package directory
rm -rf docs
mkdir docs
mkdir "docs/$PACKAGE_NAME"

# Generate jazzy docs
sourcekitten doc -- -project Example/Pods/Pods.xcodeproj -target $PACKAGE_NAME > "$LIB_PATH/swift.json"
jazzy --include-spi-declarations --sourcekitten-sourcefile "$LIB_PATH/swift.json"

# Clean build directory
rm -rf $LIB_PATH
rm -rf Example/build/
cp *.md docs/
