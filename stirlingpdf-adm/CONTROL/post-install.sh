#!/bin/sh

echo "stirlingpdf-adm: --== post-install ==--"

# --- Logging setup ---
LOG_FILE="/share/Docker/StirlingPDF/install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1>"$LOG_FILE" 2>&1
echo "=== StirlingPDF post-install started: $(date) ==="

# --- Environment variables ---
if [ -z "$APKG_PKG_DIR" ]; then
  echo "ERROR: APKG_PKG_DIR not set — is this running outside ADM?"
  exit 1
fi

if [ ! -f "$APKG_PKG_DIR/stirlingpdf_version" ]; then
  echo "ERROR: stirlingpdf_version file not found at $APKG_PKG_DIR/stirlingpdf_version"
  echo "Falling back to 'latest' tag"
  STIRLINGPDF_VERSION="latest"
else
  STIRLINGPDF_VERSION=$(cat "$APKG_PKG_DIR/stirlingpdf_version")
  STIRLINGPDF_VERSION=$(echo "$STIRLINGPDF_VERSION" | tr -d '[:space:]')
fi

if [ -z "$STIRLINGPDF_VERSION" ]; then
  echo "ERROR: stirlingpdf_version file is empty"
  STIRLINGPDF_VERSION="1.79.0"
fi

STIRLINGPDF_DATA_PATH='/share/Docker/StirlingPDF'
CONFIG_PATH='/share/Docker/StirlingPDF/config'
APP_LOGS_PATH='/share/Docker/StirlingPDF/logs'
PIPELINE_PATH='/share/Docker/StirlingPDF/pipeline'
OCR_FILE_PATH='/share/Docker/StirlingPDF/ocr'
COMPOSE_FILE="$STIRLINGPDF_DATA_PATH/docker-compose.yml"

echo "Using version: $STIRLINGPDF_VERSION"
echo "Data path: $STIRLINGPDF_DATA_PATH"
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
mkdir -p "$STIRLINGPDF_DATA_PATH"
mkdir -p "$CONFIG_PATH"

# --- Tear down any existing stack ---
echo "Removing existing containers (if any)..."
$COMPOSE_CMD -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true


# --- Generate docker-compose.yml ---
echo "Generating docker-compose.yml..."

cat > "$COMPOSE_FILE" <<COMPOSE_EOF
services:
  stirling-pdf:
    image: docker.stirlingpdf.com/stirlingtools/stirling-pdf:${STIRLINGPDF_VERSION}
    container_name: stirling-pdf
    ports:
      - '7847:8080'
    volumes:
      - ${OCR_FILE_PATH}:/usr/share/tessdata  # OCR language files
      - ${CONFIG_PATH}:/configs               # Settings & database
      - ${APP_LOGS_PATH}:/logs                     # Application logs
      - ${PIPELINE_PATH}:/pipeline             # Automation configs
    environment:
      - SECURITY_ENABLELOGIN=true      # Opt out of login (default is true / enabled)
      - SYSTEM_DEFAULTLOCALE=en-GB      # Default interface language
    restart: unless-stopped
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


# --- Wait for StirlingPDF to be reachable ---
echo "Waiting for StirlingPDF web UI to be reachable..."
i=0
while [ $i -lt 20 ]; do
  if wget -q -O /dev/null http://localhost:7847/ 2>/dev/null; then
    echo "StirlingPDF web UI is up."
    break
  fi
  echo "Waiting for StirlingPDF... ($((i+1))/20)"
  sleep 3
  i=$((i+1))
done

if [ $i -ge 20 ]; then
  echo "WARNING: StirlingPDF web UI did not respond within 60 seconds."
  echo "The container may still be initializing. Check: docker logs stirlingpdf"
fi


echo "=============================================="
echo "Setup complete!"
echo "=============================================="
echo "Access StirlingPDF at: http://$AS_NAS_INET4_IP1:7847/"
echo "Config directory: $CONFIG_PATH"
echo "Logs saved to: $LOG_FILE"
echo "=============================================="
echo "=== StirlingPDF post-install completed: $(date) ==="

exit 0
