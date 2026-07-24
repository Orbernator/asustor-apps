#!/bin/sh

echo "linkwarden-adm: --== post-install ==--"

# --- Logging setup ---
LOG_FILE="/share/Docker/Linkwarden/install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1>"$LOG_FILE" 2>&1
echo "=== Linkwarden post-install started: $(date) ==="

# --- Environment variables ---
if [ -z "$APKG_PKG_DIR" ]; then
  echo "ERROR: APKG_PKG_DIR not set — is this running outside ADM?"
  exit 1
fi

if [ ! -f "$APKG_PKG_DIR/linkwarden_version" ]; then
  echo "ERROR: linkwarden_version file not found at $APKG_PKG_DIR/linkwarden_version"
  echo "Falling back to 'latest' tag"
  LINKWARDEN_VERSION="latest"
else
  LINKWARDEN_VERSION=$(cat "$APKG_PKG_DIR/linkwarden_version")
  LINKWARDEN_VERSION=$(echo "$LINKWARDEN_VERSION" | tr -d '[:space:]')
fi

if [ -z "$LINKWARDEN_VERSION" ]; then
  echo "ERROR: linkwarden_version file is empty"
  LINKWARDEN_VERSION="v2.15.1"
fi

LINKWARDEN_DATA_PATH='/share/Docker/Linkwarden'
CONFIG_PATH='/share/Docker/Linkwarden/config'
LINKWARDEN_DB='/share/Docker/Linkwarden/db'
LINKWARDEN_ENV_PATH='/share/Docker/Linkwarden/.env'
COMPOSE_FILE="$LINKWARDEN_DATA_PATH/docker-compose.yml"

echo "Using version: $LINKWARDEN_VERSION"
echo "Data path: $LINKWARDEN_DATA_PATH"
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
mkdir -p "$LINKWARDEN_DATA_PATH"
mkdir -p "$CONFIG_PATH"

# --- Tear down any existing stack ---
echo "Removing existing containers (if any)..."
$COMPOSE_CMD -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

# --- Generate credentials ---
NEXTAUTH_SECRET=$(openssl rand -hex 32 2>/dev/null)
if [ -z "$NEXTAUTH_SECRET" ]; then
  echo "WARNING: openssl not available, using fallback key — CHANGE THIS MANUALLY"
  NEXTAUTH_SECRET="change_me_please_generate_with_openssl_rand_hex_32"
fi

POSTGRES_PASSWORD=$(openssl rand -hex 16 2>/dev/null)
if [ -z "$POSTGRES_PASSWORD" ]; then
  POSTGRES_PASSWORD="please_change_me"
fi


# --- Generate docker-compose.yml ---
echo "Generating docker-compose.yml..."

cat > "$COMPOSE_FILE" <<COMPOSE_EOF
services:
  postgres:
    image: postgres:16-alpine
    container_name: linkwarden-db
    env_file: ${LINKWARDEN_ENV_PATH}
    restart: unless-stopped
    environment:
      - POSTGRES_USER=linkwarden
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=linkwarden
    volumes:
      - ${LINKWARDEN_DB}:/var/lib/postgresql/data
  linkwarden:
    container_name: linkwarden
    env_file: ${LINKWARDEN_ENV_PATH}
    environment:
      - DATABASE_URL=postgresql://linkwarden:${POSTGRES_PASSWORD}@postgres:5432/linkwarden
    restart: unless-stopped
    image: ghcr.io/linkwarden/linkwarden:${LINKWARDEN_VERSION}
    ports:
      - 5465:3000
    volumes:
      - ${LINKWARDEN_DATA_PATH}:/data/data
    depends_on:
      - postgres
COMPOSE_EOF

echo "Generated docker-compose.yml:"
cat "$COMPOSE_FILE"

# Save generated secrets and config reference
echo ""
echo "=== Generated secrets and config ==="
echo "# Save these securely - they won't be regenerated after initial install"
echo "NEXTAUTH_URL=http://localhost:3000/api/v1/auth" >> "$LINKWARDEN_DATA_PATH/.env"
echo "NEXTAUTH_SECRET=${NEXTAUTH_SECRET}" >> "$LINKWARDEN_DATA_PATH/.env"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" >> "$LINKWARDEN_DATA_PATH/.env"
echo "# Reference .env.sample: https://raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample" 

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
echo "Waiting for PostgreSQL to be ready..."
i=0
while [ $i -lt 30 ]; do
  if docker exec linkwarden-db pg_isready -U linkwarden >/dev/null 2>&1; then
    echo "PostgreSQL is ready."
    break
  fi
  echo "Waiting... ($((i+1))/30)"
  sleep 3
  i=$((i+1))
done

if [ $i -ge 30 ]; then
  echo "ERROR: PostgreSQL did not become healthy in time — containers may still be starting"
  echo "Check logs with: docker logs linkwarden-db"
fi

# --- Wait for Linkwarden to be reachable ---
echo "Waiting for Linkwarden web UI to be reachable..."
i=0
while [ $i -lt 20 ]; do
  if wget -q -O /dev/null http://localhost:5465/ 2>/dev/null; then
    echo "Linkwarden web UI is up."
    break
  fi
  echo "Waiting for Linkwarden... ($((i+1))/20)"
  sleep 3
  i=$((i+1))
done

if [ $i -ge 20 ]; then
  echo "WARNING: Linkwarden web UI did not respond within 60 seconds."
  echo "The container may still be initializing. Check: docker logs linkwarden"
fi

echo "=============================================="
echo "Setup complete!"
echo "=============================================="
echo "Access Linkwarden at: http://$AS_NAS_INET4_IP1:5465/"
echo "First login: Use email/password registration (signups enabled by default)"
echo "Secrets saved to: $LINKWARDEN_DATA_PATH/secrets.txt"
echo "Config directory: $CONFIG_PATH"
echo "Logs saved to: $LOG_FILE"
echo "=============================================="
echo "=== Linkwarden post-install completed: $(date) ==="

exit 0
