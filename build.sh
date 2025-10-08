#!/usr/bin/env bash

set -eo pipefail                   # Exit on error
exec > >(tee $HOME/build.log) 2>&1 # Write logs

source functions.sh # Import functions

# Handle errors
trap 'err "Failed to execute command $BASH_COMMAND"' ERR

# Create workspace dir
mkdir -p workspace && cd workspace

# Isntall dependencies
log "Installing build dependencies..."
curl -LSs https://raw.githubusercontent.com/akhilnarang/scripts/refs/heads/master/setup/android_build_env.sh | bash -

# Sync TWRP manifest
log "Syncing TWRP Manifest..."
git config --global user.name "bintang774"
git config --global user.email "108184157+bintang774@users.noreply.github.com"
repo init --depth=1 -u "$TWRP_MANIFEST" -b "$TWRP_MANIFEST_BRANCH"
repo sync

# Clone Device tree
log "Cloning device tree..."
git clone --depth=1 -q "$DT_REPO" -b "$DT_BRANCH" "$DT_PATH"

# Build TWRP
log "Building TWRP..."
export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh
lunch "${DEVICE_MAKEFILE}-eng"
mka "${BUILD_TARGET}image" -j"$(nproc --all)"

# Files
OUT_PATH="out/target/product/$DEVICE_NAME"
OUTPUT_FILES=$(realpath "$OUT_PATH"/*.img)

# Create GitHub release
log "Creating GitHub release..."
export GITHUB_TOKEN="$GH_TOKEN"
DATE=$(TZ="$TIMEZONE" date +"%Y%m%d-%H%M")
RELEASE_TAG="twrp-${DEVICE_NAME}-${DATE}"
RELEASE_NAME="TWRP ${DEVICE_NAME} ${DATE}"

# Upload output file to github release
URL=$(
  gh release create "$RELEASE_TAG" \
    $OUTPUT_FILES \
    --title "$RELEASE_NAME" \
    -R "$RELEASE_REPO" \
    2> /dev/null
)

# Send notification to telegram
send_msg "*$RELEASE_NAME*\n[Download]($URL)
ambatukam aaaaa please bless this recovery"
send_file "$HOME/build.log"

exit 0
