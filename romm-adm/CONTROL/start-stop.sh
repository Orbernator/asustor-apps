#!/bin/sh

COMPOSE_FILE='/share/Docker/Romm/docker-compose.yml'

# Detect compose command
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  echo "romm-adm: ERROR: Docker Compose not found"
  exit 1
fi

case "$1" in
  start)
    echo "romm-adm: Starting service..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" up -d
    ;;
  stop)
    echo "romm-adm: Stopping service..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" stop
    ;;
  reload)
    echo "romm-adm: Restarting service..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" restart
    ;;
  *)
    echo "usage: $0 {start|stop|reload}"
    exit 1
    ;;
esac

exit 0
