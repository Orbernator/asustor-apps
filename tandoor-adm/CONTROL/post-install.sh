#!/bin/sh

echo "tandoor-adm: --== post-install ==--"

# --- Logging setup ---
LOG_FILE="/share/Docker/Tandoor/install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1>"$LOG_FILE" 2>&1
echo "=== Tandoor post-install started: $(date) ==="

# --- Environment variables ---
if [ -z "$APKG_PKG_DIR" ]; then
  echo "ERROR: APKG_PKG_DIR not set — is this running outside ADM?"
  exit 1
fi

if [ ! -f "$APKG_PKG_DIR/tandoor_version" ]; then
  echo "ERROR: tandoor_version file not found at $APKG_PKG_DIR/tandoor_version"
  echo "Falling back to 'latest' tag"
  TANDOOR_VERSION="latest"
else
  TANDOOR_VERSION=$(cat "$APKG_PKG_DIR/tandoor_version")
  TANDOOR_VERSION=$(echo "$TANDOOR_VERSION" | tr -d '[:space:]')
fi

if [ -z "$TANDOOR_VERSION" ]; then
  echo "ERROR: tandoor_version file is empty"
  TANDOOR_VERSION="latest"
fi

TANDOOR_DATA_PATH='/share/Docker/Tandoor'
TANDOOR_MEDIA_PATH='/share/Media/Tandoor'
DB_DATA_PATH='/share/Docker/Tandoor/db'
COMPOSE_FILE="$TANDOOR_DATA_PATH/docker-compose.yml"

echo "Using version: $TANDOOR_VERSION"
echo "Data path: $TANDOOR_DATA_PATH"
echo "Media path: $TANDOOR_MEDIA_PATH"
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
mkdir -p "$TANDOOR_DATA_PATH"
mkdir -p "$TANDOOR_MEDIA_PATH"
mkdir -p "$DB_DATA_PATH"

# --- Tear down any existing stack ---
echo "Removing existing containers (if any)..."
$COMPOSE_CMD -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

# --- Generate docker-compose.yml ---
echo "Generating docker-compose.yml..."

if [ -e /dev/dri ]; then
  echo "GPU device detected at /dev/dri — enabling hardware transcoding"
  cat > "$COMPOSE_FILE" <<'COMPOSE_EOF'
services:
  db:
    image: postgres:15-alpine
    restart: unless-stopped
    volumes:
      - DB_DATA_PLACEHOLDER:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=djangodb
      - POSTGRES_PASSWORD=please_change_me_postgres
      - POSTGRES_DB=djangodb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U djangodb"]
      interval: 10s
      timeout: 5s
      retries: 5

  tandoor:
    image: IMAGE_PLACEHOLDER
    restart: unless-stopped
    ports:
      - "9928:80"
    volumes:
      - STATIC_PLACEHOLDER:/opt/recipes/staticfiles
      - MEDIA_PLACEHOLDER:/opt/recipes/mediafiles
    devices:
      - /dev/dri:/dev/dri
    environment:
      - SECRET_KEY=please_change_me
      - DB_ENGINE=django.db.backends.postgresql
      - POSTGRES_HOST=db
      - POSTGRES_PORT=5432
      - POSTGRES_USER=djangodb
      - POSTGRES_PASSWORD=please_change_me_postgres
      - POSTGRES_DB=djangodb
      - ALLOWED_HOSTS=$AS_NAS_INET4_IP1
    depends_on:
      db:
        condition: service_healthy
COMPOSE_EOF
else
  echo "No GPU device at /dev/dri — skipping hardware transcoding"
  cat > "$COMPOSE_FILE" <<'COMPOSE_EOF'
services:
  db:
    image: postgres:15-alpine
    restart: unless-stopped
    volumes:
      - DB_DATA_PLACEHOLDER:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=djangodb
      - POSTGRES_PASSWORD=please_change_me_postgres
      - POSTGRES_DB=djangodb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U djangodb"]
      interval: 10s
      timeout: 5s
      retries: 5

  tandoor:
    image: IMAGE_PLACEHOLDER
    restart: unless-stopped
    ports:
      - "9928:80"
    volumes:
      - STATIC_PLACEHOLDER:/opt/recipes/staticfiles
      - MEDIA_PLACEHOLDER:/opt/recipes/mediafiles
    environment:
      - SECRET_KEY=please_change_me
      - DB_ENGINE=django.db.backends.postgresql
      - POSTGRES_HOST=db
      - POSTGRES_PORT=5432
      - POSTGRES_USER=djangodb
      - POSTGRES_PASSWORD=please_change_me_postgres
      - POSTGRES_DB=djangodb
      - ALLOWED_HOSTS=$AS_NAS_INET4_IP1
    depends_on:
      db:
        condition: service_healthy
COMPOSE_EOF
fi

# --- Substitute placeholders with real paths ---
sed -i \
  -e "s|IMAGE_PLACEHOLDER|vabene1111/recipes:${TANDOOR_VERSION}|g" \
  -e "s|DB_DATA_PLACEHOLDER|${DB_DATA_PATH}|g" \
  -e "s|STATIC_PLACEHOLDER|${TANDOOR_DATA_PATH}/staticfiles|g" \
  -e "s|MEDIA_PLACEHOLDER|${TANDOOR_MEDIA_PATH}|g" \
  "$COMPOSE_FILE"

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

# --- Wait for database to be ready ---
echo "Waiting for database to be ready..."
i=0
while [ $i -lt 30 ]; do
  if docker exec tandoor-db-1 sh -c 'pg_isready -U djangodb' >/dev/null 2>&1; then
    echo "PostgreSQL is ready."
    break
  fi
  echo "Waiting... ($((i+1))/30)"
  sleep 2
  i=$((i+1))
done

if [ $i -ge 30 ]; then
  echo "ERROR: PostgreSQL did not become ready in time"
  exit 1
fi

# --- Run database migrations ---
echo "Running database migrations..."
docker exec tandoor-tandoor-1 /opt/recipes/venv/bin/python /opt/recipes/manage.py migrate --noinput
if [ $? -ne 0 ]; then
  echo "ERROR: Migrations failed"
  exit 1
fi
echo "Migrations completed successfully."

# --- Collect static files ---
echo "Collecting static files..."
docker exec tandoor-tandoor-1 /opt/recipes/venv/bin/python /opt/recipes/manage.py collectstatic --noinput
if [ $? -ne 0 ]; then
  echo "WARNING: collectstatic failed, but continuing"
fi

# --- Create default superuser ---
echo "Setting up superuser..."
docker exec tandoor-tandoor-1 /opt/recipes/venv/bin/python /opt/recipes/manage.py shell <<'USERCHECK'
from django.contrib.auth.models import User
if User.objects.count() == 0:
    User.objects.create_superuser('admin', 'admin@localhost', 'changeme')
    print('Admin user created: admin / changeme')
else:
    print('Superuser already exists')
USERCHECK

echo "Setup complete!"
echo "=== Tandoor post-install completed: $(date) ==="
echo "Logs saved to: $LOG_FILE"

exit 0
