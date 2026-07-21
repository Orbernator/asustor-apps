#!/bin/sh

echo "tandoor-adm: --== pre-uninstall ==--"

# Environment variables
TANDOOR_VERSION=$(cat $APKG_PKG_DIR/tandoor_version)
TANDOOR_CONTAINER=$(docker container ls -a | grep Tandoor | awk '{print $1}')
TANDOOR_IMAGE=$(docker images | grep chrisbenincasa/tandoor | grep $TANDOOR_VERSION | awk '{print $3}')

# Force shutdown of the container and delete it
echo "tandoor-adm: Stopping and removing container"
echo "    - $TANDOOR_CONTAINER"
if [ -n "$TANDOOR_CONTAINER" ]; then
  docker kill "$TANDOOR_CONTAINER"
  sleep 2
  docker rm -f "$TANDOOR_CONTAINER"
fi

# REMOVE docker image on uninstalling & updating
echo "tandoor-adm: Removing docker image"
echo "tandoor-adm: Image ID: $TANDOOR_IMAGE"
if [ -n "$TANDOOR_IMAGE" ]; then
  docker rmi -f "$TANDOOR_IMAGE"
fi

exit 0
