#!/bin/sh

echo "tunarr-adm: --== pre-uninstall ==--"

# Environment variables
TUNARR_VERSION=$(cat $APKG_PKG_DIR/tunarr_version)
TUNARR_CONTAINER=$(docker container ls -a | grep Tunarr | awk '{print $1}')
TUNARR_IMAGE=$(docker images | grep chrisbenincasa/tunarr | grep $TUNARR_VERSION | awk '{print $3}')

# Force shutdown of the container and delete it
echo "tunarr-adm: Stopping and removing container"
echo "    - $TUNARR_CONTAINER"
if [ -n "$TUNARR_CONTAINER" ]; then
  docker kill "$TUNARR_CONTAINER"
  sleep 2
  docker rm -f "$TUNARR_CONTAINER"
fi

# REMOVE docker image on uninstalling & updating
echo "tunarr-adm: Removing docker image"
echo "tunarr-adm: Image ID: $TUNARR_IMAGE"
if [ -n "$TUNARR_IMAGE" ]; then
  docker rmi -f "$TUNARR_IMAGE"
fi

exit 0
