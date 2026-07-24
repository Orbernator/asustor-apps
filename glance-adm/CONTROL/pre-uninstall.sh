#!/bin/sh

echo "glance-adm: --== pre-uninstall ==--"


# Environment variables
GLANCE_VERSION=$(cat $APKG_PKG_DIR/glance_version)
GLANCE_CONTAINER=$(docker container ls -a | grep glance | awk '{print $1}')
GLANCE_IMAGE=$(docker images | grep glanceapp/glance | grep $GLANCE_VERSION | awk '{print $3}')

# Force shutdown of the container and delete it
echo "glance-adm: Stopping and removing container"
echo "    - $GLANCE_CONTAINER"
if [ -n "$GLANCE_CONTAINER" ]; then
  docker kill "$GLANCE_CONTAINER"
  sleep 2
  docker rm -f "$GLANCE_CONTAINER"
fi

# REMOVE docker image on uninstalling & updating
echo "glance-adm: Removing docker image"
echo "glance-adm: Image ID: $GLANCE_IMAGE"
if [ -n "$GLANCE_IMAGE" ]; then
  docker rmi -f "$GLANCE_IMAGE"
fi

exit 0