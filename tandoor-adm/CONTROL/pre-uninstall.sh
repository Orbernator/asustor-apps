#!/bin/sh

echo "tandoor-adm: --== pre-uninstall ==--"

# Environment variables
TANDOOR_VERSION=$(cat $APKG_PKG_DIR/tandoor_version)
TANDOOR_CONTAINERS=$(docker container ls -a | grep 'tandoor|tandoor-db' | awk '{print $1}')
TANDOOR_IMAGE=$(docker images | grep vabene1111/tandoor | grep $NAVIDROME_VERSION | awk '{print $3}')
POSTGRES_IMAGE_IMAGE=$(docker images | grep postgres | grep 15-alpine | awk '{print $3}')

# Force shutdown of the containers and delete them
echo "tandoor-adm: Stopping and removing container"
echo "    - $TANDOOR_CONTAINER"
if [ -n "$TANDOOR_CONTAINER" ]; then
  docker kill "$TANDOOR_CONTAINER"
  sleep 2
  docker rm -f "$TANDOOR_CONTAINER"
fi


# Remove docker images on uninstalling
echo "tandoor-adm: Removing docker image"
echo "tandoor-adm: Image ID: $TANDOOR_IMAGE"
if [ -n "$TANDOOR_IMAGE" ]; then
  docker rmi -f "$TANDOOR_IMAGE"
fi
echo "tandoor-adm: Image ID: $POSTGRES_IMAGE"
if [ -n "$POSTGRES_IMAGE" ]; then
  docker rmi -f "$POSTGRES_IMAGE"
fi

# Optional: Remove volumes (comment out if you want to preserve data)
# docker volume rm tandoor-docker_tandoor-data 2>/dev/null || true
# docker volume rm tandoor-docker_db-data 2>/dev/null || true

exit 0
