#!/bin/sh

echo "musicassistant-adm: --== post-install ==--"

# --- Logging setup ---
LOG_FILE="/share/Docker/MusicAssistant/install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1>"$LOG_FILE" 2>&1
echo "=== MusicAssistant post-install started: $(date) ==="

# --- Environment variables ---
if [ -z "$APKG_PKG_DIR" ]; then
  echo "ERROR: APKG_PKG_DIR not set — is this running outside ADM?"
  exit 1
fi

if [ ! -f "$APKG_PKG_DIR/musicassistant_version" ]; then
  echo "ERROR: musicassistant_version file not found at $APKG_PKG_DIR/musicassistant_version"
  echo "Falling back to 'latest' tag"
  MUSIC_ASSISTANT_VERSION="latest"
else
  MUSIC_ASSISTANT_VERSION=$(cat "$APKG_PKG_DIR/musicassistant_version")
  MUSIC_ASSISTANT_VERSION=$(echo "$MUSIC_ASSISTANT_VERSION" | tr -d '[:space:]')
fi

if [ -z "$MUSIC_ASSISTANT_VERSION" ]; then
  echo "ERROR: musicassistant_version file is empty"
  MUSIC_ASSISTANT_VERSION="v2.9.13"
fi

MUSIC_ASSISTANT_DATA_PATH='/share/Docker/MusicAssistant'
MUSIC_ASSISTANT_CONFIG='/share/Docker/MusicAssistant/config'
MUSIC_ASSISTANT_DB='/share/Docker/MusicAssistant/db'
COMPOSE_FILE="$MUSIC_ASSISTANT_DATA_PATH/docker-compose.yml"

echo "Using version: $MUSIC_ASSISTANT_VERSION"
echo "Data path: $MUSIC_ASSISTANT_DATA_PATH"
echo "Config path: $CONFIG_PATH"
echo "Compose file: $COMPOSE_FILE"

# --- Check Docker is running ---
echo "Checking Docker daemon..."
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon is not running"
  exit 1
fi
echo "Docker is running."

# --- Detect compose command ---
COMPOSE_CMD=""
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  echo "ERROR: Neither 'docker compose' (plugin) nor 'docker-compose' (standalone) is available"
  exit 1
fi
echo "Using compose command: $COMPOSE_CMD"

# --- Ensure directories exist ---
echo "Creating directories..."
mkdir -p "$MUSIC_ASSISTANT_DATA_PATH"
mkdir -p "$CONFIG_PATH"

# --- Tear down any existing stack ---
echo "Removing existing containers (if any)..."
$COMPOSE_CMD -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true


# --- Generate docker-compose.yml ---
echo "Generating docker-compose.yml..."

cat > "$COMPOSE_FILE" <<COMPOSE_EOF
services:
  music-assistant-server:
    image: ghcr.io/music-assistant/server:${MUSIC_ASSISTANT_VERSION}
    container_name: music-assistant
    restart: unless-stopped
    # Network mode must be set to host for MA to discover and stream to players (see networking note below)
    network_mode: host
    volumes:
      - ${MUSIC_ASSISTANT_CONFIG}:/data/
      # Optional: expose local music to MA by bind-mounting it read-only
    environment:
      # Provide logging level as environment variable.
      # default=info, possible=(critical, error, warning, info, debug)
      - LOG_LEVEL=info
COMPOSE_EOF

echo "Generated docker-compose.yml:"
cat "$COMPOSE_FILE"


# --- Pull images ---
echo "Pulling images..."
$COMPOSE_CMD -f "$COMPOSE_FILE" pull
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to pull images"
  exit 1
fi
echo "Images pulled successfully."

# --- Start the stack ---
echo "Starting containers..."
$COMPOSE_CMD -f "$COMPOSE_FILE" up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start containers"
  exit 1
fi
echo "Containers started successfully."


# --- Wait for MusicAssistant to be reachable ---
echo "Waiting for MusicAssistant web UI to be reachable..."
i=0
while [ $i -lt 20 ]; do
  if wget -q -O /dev/null http://localhost:8095/ 2>/dev/null; then
    echo "MusicAssistant web UI is up."
    break
  fi
  echo "Waiting for MusicAssistant... ($((i+1))/20)"
  sleep 3
  i=$((i+1))
done

if [ $i -ge 20 ]; then
  echo "WARNING: MusicAssistant web UI did not respond within 60 seconds."
  echo "The container may still be initializing. Check: docker logs musicassistant"
fi

echo "=============================================="
echo "Setup complete!"
echo "=============================================="
echo "Access MusicAssistant at: http://$AS_NAS_INET4_IP1:8095/"
echo "First login: Use email/password registration (signups enabled by default)"
echo "Config directory: $CONFIG_PATH"
echo "Logs saved to: $LOG_FILE"
echo "=============================================="
echo "=== MusicAssistant post-install completed: $(date) ==="

exit 0
