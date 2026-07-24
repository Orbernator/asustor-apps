#!/bin/sh

echo "glance-adm: --== post-install ==--"

# --- Logging setup ---
LOG_FILE="/share/Docker/Glance/install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1>"$LOG_FILE" 2>&1
echo "=== Glance post-install started: $(date) ==="

# --- Environment variables ---
if [ -z "$APKG_PKG_DIR" ]; then
  echo "ERROR: APKG_PKG_DIR not set — is this running outside ADM?"
  exit 1
fi

if [ ! -f "$APKG_PKG_DIR/glance_version" ]; then
  echo "ERROR: glance_version file not found at $APKG_PKG_DIR/glance_version"
  echo "Falling back to 'latest' tag"
  GLANCE_VERSION="latest"
else
  GLANCE_VERSION=$(cat "$APKG_PKG_DIR/glance_version")
  GLANCE_VERSION=$(echo "$GLANCE_VERSION" | tr -d '[:space:]')
fi

if [ -z "$GLANCE_VERSION" ]; then
  echo "ERROR: glance_version file is empty"
  GLANCE_VERSION="0.8.5"
fi

GLANCE_DATA_PATH='/share/Docker/Glance'
GLANCE_CONFIG_PATH='/share/Docker/Glance/config'
COMPOSE_FILE="$GLANCE_DATA_PATH/docker-compose.yml"
GLANCEYML_FILE="$GLANCE_CONFIG_PATH/glance.yml"

echo "Using version: $GLANCE_VERSION"
echo "Data path: $GLANCE_DATA_PATH"
echo "Config path: $GLANCE_CONFIG_PATH"
echo "Compose file: $COMPOSE_FILE"
echo "Glance.yml file: $GLANCEYML_FILE"

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
mkdir -p "$GLANCE_DATA_PATH"
mkdir -p "$GLANCE_CONFIG_PATH"
# --- Tear down any existing stack ---
echo "Removing existing containers (if any)..."
$COMPOSE_CMD -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

# --- Generate docker-compose.yml ---
echo "Generating docker-compose.yml..."

cat > "$COMPOSE_FILE" <<COMPOSE_EOF
services:
  glance:
    container_name: glance
    image: glanceapp/glance:${GLANCE_VERSION}
    restart: unless-stopped
    volumes:
      - ${GLANCE_CONFIG_PATH}:/app/config
    ports:
      - 4523:8080
COMPOSE_EOF

echo "Generated docker-compose.yml:"
cat "$COMPOSE_FILE"

echo "Generating default Glance.yml file..."

cat > "$GLANCEYML_FILE" <<GLANCEYML
pages:
  - name: Home
    # Optionally, if you only have a single page you can hide the desktop navigation for a cleaner look
    # hide-desktop-navigation: true
    columns:
      - size: small
        widgets:
          - type: calendar
            first-day-of-week: monday

          - type: rss
            limit: 10
            collapse-after: 3
            cache: 12h
            feeds:
              - url: https://selfh.st/rss/
                title: selfh.st
                limit: 4
              - url: https://ciechanow.ski/atom.xml
              - url: https://www.joshwcomeau.com/rss.xml
                title: Josh Comeau
              - url: https://samwho.dev/rss.xml
              - url: https://ishadeed.com/feed.xml
                title: Ahmad Shadeed

          - type: twitch-channels
            channels:
              - theprimeagen
              - j_blow
              - giantwaffle
              - cohhcarnage
              - christitustech
              - EJ_SA

      - size: full
        widgets:
          - type: group
            widgets:
              - type: hacker-news
              - type: lobsters

          - type: videos
            channels:
              - UCXuqSBlHAE6Xw-yeJA0Tunw # Linus Tech Tips
              - UCR-DXc1voovS8nhAvccRZhg # Jeff Geerling
              - UCsBjURrPoezykLs9EqgamOA # Fireship
              - UCBJycsmduvYEL83R_U4JriQ # Marques Brownlee
              - UCHnyfMqiRRG1u-2MsSQLbXA # Veritasium

          - type: group
            widgets:
              - type: reddit
                subreddit: technology
                show-thumbnails: true
              - type: reddit
                subreddit: selfhosted
                show-thumbnails: true

      - size: small
        widgets:
          - type: weather
            location: London, United Kingdom
            units: metric # alternatively "imperial"
            hour-format: 12h # alternatively "24h"
            # Optionally hide the location from being displayed in the widget
            # hide-location: true

          - type: markets
            markets:
              - symbol: SPY
                name: S&P 500
              - symbol: BTC-USD
                name: Bitcoin
              - symbol: NVDA
                name: NVIDIA
              - symbol: AAPL
                name: Apple
              - symbol: MSFT
                name: Microsoft

          - type: releases
            cache: 1d
            # Without authentication the Github API allows for up to 60 requests per hour. You can create a
            # read-only token from your Github account settings and use it here to increase the limit.
            # token: ...
            repositories:
              - glanceapp/glance
              - go-gitea/gitea
              - immich-app/immich
              - syncthing/syncthing
              - orbernator/asustor-apps

  # Add more pages here:
  # - name: Your page name
  #   columns:
  #     - size: small
  #       widgets:
  #         # Add widgets here

  #     - size: full
  #       widgets:
  #         # Add widgets here

  #     - size: small
  #       widgets:
  #         # Add widgets here
GLANCEYML

echo "Generated Glance.yml:"
cat "$GLANCEYML_FILE"

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

# --- Wait for Glance to be reachable ---
echo "Waiting for Glance web UI to be reachable..."
i=0
while [ $i -lt 20 ]; do
  if wget -q -O /dev/null http://localhost:4523/ 2>/dev/null; then
    echo "Glance web UI is up."
    break
  fi
  echo "Waiting for Glance... ($((i+1))/20)"
  sleep 3
  i=$((i+1))
done

if [ $i -ge 20 ]; then
  echo "WARNING: Glance web UI did not respond within 60 seconds."
  echo "The container may still be initializing. Check: docker logs glance"
fi

echo "Setup complete!"
echo "Access Glance at: http://$AS_NAS_INET4_IP1:4523/"
echo "=== Glance post-install completed: $(date) ==="
echo "Logs saved to: $LOG_FILE"

exit 0
