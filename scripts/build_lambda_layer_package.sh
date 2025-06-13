#!/bin/bash

set -e

# Input args:
# $1 = layer name (e.g. shared-utils-layer)
# $2 = path to layer source directory (e.g. ./layers/shared_utils)

LAYER_NAME=$1
SOURCE_PATH=$(realpath "$2")

REQUIREMENTS_PATH="$SOURCE_PATH/requirements.txt"
LAYER_BUILD_DIR="$SOURCE_PATH/build"
PYTHON_DIR="$LAYER_BUILD_DIR/python"
ZIP_PATH="$SOURCE_PATH/$LAYER_NAME.zip"

echo "🧹 Cleaning previous build artifacts..."
rm -rf "$LAYER_BUILD_DIR" "$ZIP_PATH"
mkdir -p "$PYTHON_DIR"

# Install any dependencies to python/ dir
if [[ -f "$REQUIREMENTS_PATH" ]]; then
  echo "📦 Installing dependencies from $REQUIREMENTS_PATH"
  pip install -r "$REQUIREMENTS_PATH" -t "$PYTHON_DIR"
fi

# Copy Python source files into python/
echo "📁 Copying Python files to layer"
find "$SOURCE_PATH" -maxdepth 1 -name "*.py" -exec cp {} "$PYTHON_DIR/" \;

echo "📦 Creating layer ZIP: $ZIP_PATH"
cd "$LAYER_BUILD_DIR"
zip -r "$ZIP_PATH" python > /dev/null

echo "✅ Lambda layer package created at: $ZIP_PATH"
