#!/bin/sh

echo "romm-adm: --== post-install ==--"

# --- Logging setup ---
LOG_FILE="/share/Docker/Romm/install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1>"$LOG_FILE" 2>&1
echo "=== Romm post-install started: $(date) ==="

# --- Environment variables ---
if [ -z "$APKG_PKG_DIR" ]; then
  echo "ERROR: APKG_PKG_DIR not set — is this running outside ADM?"
  exit 1
fi

if [ ! -f "$APKG_PKG_DIR/romm_version" ]; then
  echo "ERROR: romm_version file not found at $APKG_PKG_DIR/romm_version"
  echo "Falling back to 'latest' tag"
  ROMM_VERSION="latest"
else
  ROMM_VERSION=$(cat "$APKG_PKG_DIR/romm_version")
  ROMM_VERSION=$(echo "$ROMM_VERSION" | tr -d '[:space:]')
fi

if [ -z "$ROMM_VERSION" ]; then
  echo "ERROR: romm_version file is empty"
  ROMM_VERSION="5.0.0"
fi

ROMM_DATA_PATH='/share/Docker/Romm'
ROMM_LIBRARY_PATH='/share/Media/Romm/library'
ROMM_ASSETS_PATH='/share/Media/Romm/assets'
ROMM_CONFIG_PATH='/share/Docker/Romm/config'
DB_DATA_PATH='/share/Docker/Romm/db'
COMPOSE_FILE="$ROMM_DATA_PATH/docker-compose.yml"

echo "Using version: $ROMM_VERSION"
echo "Data path: $ROMM_DATA_PATH"
echo "Library path: $ROMM_LIBRARY_PATH"
echo "Assets path: $ROMM_ASSETS_PATH"
echo "Config path: $ROMM_CONFIG_PATH"
echo "DB data path: $DB_DATA_PATH"
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
mkdir -p "$ROMM_DATA_PATH"
mkdir -p "$ROMM_LIBRARY_PATH"
mkdir -p "$ROMM_ASSETS_PATH"
mkdir -p "$ROMM_CONFIG_PATH"
mkdir -p "$DB_DATA_PATH"

# --- Tear down any existing stack ---
echo "Removing existing containers (if any)..."
$COMPOSE_CMD -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

# --- Generate auth secret key ---
ROMM_AUTH_SECRET_KEY=$(openssl rand -hex 32 2>/dev/null)
if [ -z "$ROMM_AUTH_SECRET_KEY" ]; then
  echo "WARNING: openssl not available, using fallback key — CHANGE THIS MANUALLY"
  ROMM_AUTH_SECRET_KEY="change_me_please_generate_with_openssl_rand_hex_32"
fi

# --- Generate MariaDB password ---
MARIADB_ROOT_PASSWORD=$(openssl rand -hex 16 2>/dev/null)
if [ -z "$MARIADB_ROOT_PASSWORD" ]; then
  MARIADB_ROOT_PASSWORD="please_change_me_root"
fi

MARIADB_PASSWORD=$(openssl rand -hex 16 2>/dev/null)
if [ -z "$MARIADB_PASSWORD" ]; then
  MARIADB_PASSWORD="please_change_me"
fi

# --- Generate docker-compose.yml ---
echo "Generating docker-compose.yml..."

cat > "$COMPOSE_FILE" <<COMPOSE_EOF
services:
  romm:
    image: rommapp/romm:${ROMM_VERSION}
    container_name: romm
    restart: unless-stopped
    environment:
      - DB_HOST=romm-db
      - DB_NAME=romm
      - DB_USER=romm-user
      - DB_PASSWD=${MARIADB_PASSWORD}
      - ROMM_AUTH_SECRET_KEY=${ROMM_AUTH_SECRET_KEY}
      - HASHEOUS_API_ENABLED=true
    volumes:
      - romm_resources:/romm/resources
      - romm_redis_data:/redis-data
      - ${ROMM_LIBRARY_PATH}:/romm/library
      - ${ROMM_ASSETS_PATH}:/romm/assets
      - ${ROMM_CONFIG_PATH}:/romm/config
    ports:
      - "7666:8080"
    depends_on:
      romm-db:
        condition: service_healthy
        restart: true

  romm-db:
    image: mariadb:latest
    container_name: romm-db
    restart: unless-stopped
    environment:
      - MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MARIADB_DATABASE=romm
      - MARIADB_USER=romm-user
      - MARIADB_PASSWORD=${MARIADB_PASSWORD}
    volumes:
      - ${DB_DATA_PATH}:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      start_period: 30s
      start_interval: 10s
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  romm_resources:
  romm_redis_data:
COMPOSE_EOF

echo "Generated docker-compose.yml:"
cat "$COMPOSE_FILE"

# Save generated secrets for reference
echo ""
echo "=== Generated secrets (save these!) ===" > "$ROMM_DATA_PATH/secrets.txt"
echo "ROMM_AUTH_SECRET_KEY=${ROMM_AUTH_SECRET_KEY}" >> "$ROMM_DATA_PATH/secrets.txt"
echo "MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}" >> "$ROMM_DATA_PATH/secrets.txt"
echo "MARIADB_PASSWORD=${MARIADB_PASSWORD}" >> "$ROMM_DATA_PATH/secrets.txt"
chmod 600 "$ROMM_DATA_PATH/secrets.txt"

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

# --- Wait for database to be ready ---
echo "Waiting for MariaDB to be ready..."
i=0
while [ $i -lt 30 ]; do
  if docker exec romm-db healthcheck.sh --connect --innodb_initialized >/dev/null 2>&1; then
    echo "MariaDB is ready."
    break
  fi
  echo "Waiting... ($((i+1))/30)"
  sleep 3
  i=$((i+1))
done

if [ $i -ge 30 ]; then
  echo "ERROR: MariaDB did not become healthy in time — containers may still be starting"
  echo "Check logs with: docker logs romm-db"
  # Not exiting with error — Romm will retry connecting on startup
fi

# --- Wait for Romm to be reachable ---
echo "Waiting for Romm web UI to be reachable..."
i=0
while [ $i -lt 20 ]; do
  if wget -q -O /dev/null http://localhost:7666/ 2>/dev/null; then
    echo "Romm web UI is up."
    break
  fi
  echo "Waiting for Romm... ($((i+1))/20)"
  sleep 3
  i=$((i+1))
done

if [ $i -ge 20 ]; then
  echo "WARNING: Romm web UI did not respond within 60 seconds."
  echo "The container may still be initializing. Check: docker logs romm"
fi

echo "Setup complete!"
echo "Access Romm at: http://$AS_NAS_INET4_IP1:7666/"
echo "Secrets saved to: $ROMM_DATA_PATH/secrets.txt"
echo "=== Romm post-install completed: $(date) ==="
echo "Logs saved to: $LOG_FILE"

exit 0
