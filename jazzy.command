#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Creating docs for the SwiftBMLSDK library..."

rm -rf docs .build build
mkdir -p docs

export SWIFTBMLSDK_DOCS=1

jazzy \
    --module SwiftBMLSDK \
    --swift-build-tool spm \
    --readme ./README.md \
    --github_url https://github.com/LittleGreenViper/SwiftBMLSDK \
    --title "SwiftBMLSDK Documentation" \
    --min_acl public \
    --theme fullwidth

if [ -f ./icon.png ]; then
    cp ./icon.png docs/
fi
