#!/bin/sh

echo "navidrome-adm: --== pre-uninstall ==--"

# Environment variables
NAVIDROME_VERSION=$(cat $APKG_PKG_DIR/navidrome_version)
NAVIDROME_CONTAINER=$(docker container ls -a | grep Navidrome | awk '{print $1}')
NAVIDROME_IMAGE=$(docker images | grep chrisbenincasa/navidrome | grep $NAVIDROME_VERSION | awk '{print $3}')

# Force shutdown of the container and delete it
echo "navidrome-adm: Stopping and removing container"
echo "    - $NAVIDROME_CONTAINER"
if [ -n "$NAVIDROME_CONTAINER" ]; then
  docker kill "$NAVIDROME_CONTAINER"
  sleep 2
  docker rm -f "$NAVIDROME_CONTAINER"
fi

# REMOVE docker image on uninstalling & updating
echo "navidrome-adm: Removing docker image"
echo "navidrome-adm: Image ID: $NAVIDROME_IMAGE"
if [ -n "$NAVIDROME_IMAGE" ]; then
  docker rmi -f "$NAVIDROME_IMAGE"
fi

exit 0
