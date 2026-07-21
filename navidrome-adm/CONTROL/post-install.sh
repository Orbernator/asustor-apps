#!/bin/sh

echo "navidrome-adm: --== post-install ==--"

# --- Logging setup ---
LOG_FILE="/share/Docker/Navidrome/install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1>"$LOG_FILE" 2>&1
echo "=== Navidrome post-install started: $(date) ==="

# --- Error handling ---
set -e

# --- Environment variables ---
if [ -z "$APKG_PKG_DIR" ]; then
  echo "ERROR: APKG_PKG_DIR not set — is this running outside ADM?"
  exit 1
fi

if [ ! -f "$APKG_PKG_DIR/navidrome_version" ]; then
  echo "ERROR: navidrome_version file not found at $APKG_PKG_DIR/navidrome_version"
  echo "Falling back to 'latest' tag"
  NAVIDROME_VERSION="latest"
else
  NAVIDROME_VERSION=$(cat "$APKG_PKG_DIR/navidrome_version")
  NAVIDROME_VERSION=$(echo "$NAVIDROME_VERSION" | tr -d '[:space:]')
fi

if [ -z "$NAVIDROME_VERSION" ]; then
  echo "ERROR: navidrome_version file is empty"
  NAVIDROME_VERSION="latest"
fi

NAVIDROME_DATA_PATH='/share/Docker/Navidrome'
NAVIDROME_MUSIC_PATH='/share/Media/Navidrome'
NAVIDROME_CONTAINER='Navidrome'

echo "Using version: $NAVIDROME_VERSION"
echo "Data path: $NAVIDROME_DATA_PATH"
echo "Music path: $NAVIDROME_MUSIC_PATH"
echo "Container name: $NAVIDROME_CONTAINER"

# --- Check Docker is running ---
echo "Checking Docker daemon..."
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon is not running"
  exit 1
fi
echo "Docker is running."

# --- Ensure data directory exists ---
echo "Creating data directory..."
mkdir -p "$NAVIDROME_DATA_PATH"

# --- Remove existing container if present ---
echo "Removing existing container (if any)..."
docker rm -f "$NAVIDROME_CONTAINER" 2>/dev/null || true

# --- Pull the container image ---
echo "Pulling image deluan/navidrome:$NAVIDROME_VERSION ..."
docker pull "deluan/navidrome:$NAVIDROME_VERSION"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to pull image"
  exit 1
fi
echo "Image pulled successfully."

# --- Create container ---
echo "Creating container..."
if [ -e /dev/dri ]; then
  echo "GPU device detected at /dev/dri — enabling hardware transcoding"
  docker create -i -t --name="$NAVIDROME_CONTAINER" \
    --publish 4533:4533 \
    --restart=unless-stopped \
    --volume "$NAVIDROME_DATA_PATH":/data \
    --volume "$NAVIDROME_MUSIC_PATH":/music \
    "deluan/navidrome:$NAVIDROME_VERSION"
else
  echo "No GPU device at /dev/dri — skipping hardware transcoding"
  docker create -i -t --name="$NAVIDROME_CONTAINER" \
    --publish 4533:4533 \
    --restart=unless-stopped \
    --volume "$NAVIDROME_DATA_PATH":/data \
    --volume "$NAVIDROME_MUSIC_PATH":/music \
    "deluan/navidrome:$NAVIDROME_VERSION"
fi

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create container"
  exit 1
fi
echo "Container created successfully."

# --- Start container ---
echo "Starting container..."
docker start "$NAVIDROME_CONTAINER"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start container"
  exit 1
fi
echo "Container started successfully."

echo "=== Navidrome post-install completed: $(date) ==="
echo "Logs saved to: $LOG_FILE"

exit 0
