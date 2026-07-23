#!/bin/sh

echo "youtarr-adm: --== post-install ==--"

# --- Logging setup ---
LOG_FILE="/share/Docker/Youtarr/install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1>"$LOG_FILE" 2>&1
echo "=== Youtarr post-install started: $(date) ==="

# --- Environment variables ---
if [ -z "$APKG_PKG_DIR" ]; then
  echo "ERROR: APKG_PKG_DIR not set — is this running outside ADM?"
  exit 1
fi

if [ ! -f "$APKG_PKG_DIR/youtarr_version" ]; then
  echo "ERROR: youtarr_version file not found at $APKG_PKG_DIR/youtarr_version"
  echo "Falling back to 'latest' tag"
  YOUTARR_VERSION="latest"
else
  YOUTARR_VERSION=$(cat "$APKG_PKG_DIR/youtarr_version")
  YOUTARR_VERSION=$(echo "$YOUTARR_VERSION" | tr -d '[:space:]')
fi

if [ -z "$YOUTARR_VERSION" ]; then
  echo "ERROR: youtarr_version file is empty"
  YOUTARR_VERSION="1.76.1"
fi

YOUTARR_DATA_PATH='/share/Docker/Youtarr'
CONFIG_PATH='/share/Docker/Youtarr/config'
IMAGES_PATH='/share/Docker/Youtarr/images'
JOBS_PATH='/share/Docker/Youtarr/jobs'
YOUTARR_OUTPUT_DIR='/share/Download/Youtarr'
DB_DATA_PATH='/share/Docker/Youtarr/db'
COMPOSE_FILE="$YOUTARR_DATA_PATH/docker-compose.yml"

echo "Using version: $YOUTARR_VERSION"
echo "Data path: $YOUTARR_DATA_PATH"
echo "Config path: $CONFIG_PATH"
echo "Images path: $IMAGES_PATH"
echo "Jobs path: $JOBS_PATH"
echo "Youtarr output path $YOUTARR_OUTPUT_DIR"
echo "DB Data Path: $DB_DATA_PATH"
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
mkdir -p "$YOUTARR_DATA_PATH"
mkdir -p "$YOUTARR_OUTPUT_DIR"
mkdir -p "$CONFIG_PATH"

# --- Tear down any existing stack ---
echo "Removing existing containers (if any)..."
$COMPOSE_CMD -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

# --- Generate credentials ---

MARIA_PASSWORD=$(openssl rand -hex 16 2>/dev/null)
if [ -z "$MARIA_PASSWORD" ]; then
  MARIA_PASSWORD="please_change_me"
fi

MARIA_ROOT_PASSWORD=$(openssl rand -hex 16 2>/dev/null)
if [ -z "$MARIA_ROOT_PASSWORD" ]; then
  MARIA_ROOT_PASSWORD="please_change_me_root"
fi

# --- Generate docker-compose.yml ---
echo "Generating docker-compose.yml..."

cat > "$COMPOSE_FILE" <<COMPOSE_EOF
services:
  youtarr-db:
    image: mariadb:10.3
    container_name: youtarr-db
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD= ${MARIA_ROOT_PASSWORD}
      - MYSQL_DATABASE=youtarr
      - MYSQL_TCP_PORT= ${DB_PORT:-3321}
      - MYSQL_USER=youtarr_user
      - MYSQL_PASSWORD=${MARIA_PASSWORD}
      - MYSQL_CHARSET=utf8mb4
      - MYSQL_COLLATION=utf8mb4_unicode_ci
    volumes:
      - ${DB_DATA_PATH}:/var/lib/mysql
    command: --port=${DB_PORT:-3321} --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --innodb-file-per-table=1 --innodb-large-prefix=ON
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-P", "${DB_PORT:-3321}", "-u", "${DB_USER:-root}", "-p${DB_PASSWORD:-123qweasd}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  youtarr:
    image: dialmaster/youtarr:${YOUTARR_VERSION}
    container_name: youtarr
    restart: unless-stopped
    depends_on:
      youtarr-db:
        condition: service_healthy
    environment:
      # DEPRECATED but retained for backwards compatibility with old images for now
      - IN_DOCKER_CONTAINER=1
      - TZ=$AS_NAS_TIMEZONE
      - DB_HOST=youtarr-db
      - DB_PORT=3321
      - DB_USER=youtarr_user
      - DB_PASSWORD=${MARIA_PASSWORD}
      - DB_NAME=youtarr
      # Optional: Seed initial admin credentials for headless deployments
      - AUTH_PRESET_USERNAME=admin
      - AUTH_PRESET_PASSWORD=admin
      # Logging configuration
      - LOG_LEVEL=info
      # This is just informational and lets the app know where the videos will be stored on the host
      - YOUTUBE_OUTPUT_DIR=${YOUTARR_OUTPUT_DIR}

    ports:
      - "3087:3011"
    volumes:
      - ${YOUTARR_OUTPUT_DIR}:/usr/src/app/data
      - ${IMAGES_PATH}:/app/server/images
      - ${CONFIG_PATH}:/app/config
      - ${JOBS_PATH}:/app/jobs
    healthcheck:
      test: ["CMD", "curl", "--fail", "--silent", "--show-error", "--output", "/dev/null", "http://localhost:3011/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s


COMPOSE_EOF

echo "Generated docker-compose.yml:"
cat "$COMPOSE_FILE"

# Save generated secrets and config reference
echo ""
echo "=== Generated secrets and config ===" > "$YOUTARR_DATA_PATH/secrets.txt"
echo "# Save these securely - they won't be regenerated after initial install" >> "$YOUTARR_DATA_PATH/secrets.txt"
echo "MARIA_PASSWORD=${MARIA_PASSWORD}" >> "$YOUTARR_DATA_PATH/secrets.txt"
echo "MARIA_ROOT_PASSWORD=${MARIA_ROOT_PASSOWRD}" >> "$YOUTARR_DATA_PATH/secrets.txt"
echo "" >> "$YOUTARR_DATA_PATH/secrets.txt"
chmod 600 "$YOUTARR_DATA_PATH/secrets.txt"

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


# --- Wait for Youtarr to be reachable ---
echo "Waiting for Youtarr web UI to be reachable..."
i=0
while [ $i -lt 20 ]; do
  if wget -q -O /dev/null http://localhost:3087/ 2>/dev/null; then
    echo "Youtarr web UI is up."
    break
  fi
  echo "Waiting for Youtarr... ($((i+1))/20)"
  sleep 3
  i=$((i+1))
done

if [ $i -ge 20 ]; then
  echo "WARNING: Youtarr web UI did not respond within 60 seconds."
  echo "The container may still be initializing. Check: docker logs youtarr"
fi

mv $CONFIG_PATH/setup-token $CONFIG_PATH/setup-token.txt

echo "=============================================="
echo "Setup complete!"
echo "=============================================="
echo "Access Youtarr at: http://$AS_NAS_INET4_IP1:3087/"
echo "First login: Use email/password registration (signups enabled by default)"
echo "Secrets saved to: $YOUTARR_DATA_PATH/secrets.txt"
echo "Config directory: $CONFIG_PATH"
echo "Logs saved to: $LOG_FILE"
echo "=============================================="
echo "=== Youtarr post-install completed: $(date) ==="

exit 0
