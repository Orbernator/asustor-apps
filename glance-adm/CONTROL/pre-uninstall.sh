#!/bin/sh

echo "glance-adm: --== pre-uninstall ==--"

# Environment variables
GLANCE_VERSION=$(cat $APKG_PKG_DIR/glance_version)
GLANCE_CONTAINER=$(docker container ls -a | grep -E '^glance\b' | awk '{print $1}')
GLANCE_IMAGE=$(docker images | grep glanceapp/glance | grep $GLANCE_VERSION | awk '{print $3}')

# Force shutdown of the containers and delete them
echo "glance-adm: Stopping and removing containers"
for cid in $GLANCE_CONTAINER; do
  echo "    - $cid"
  docker kill "$cid" 2>/dev/null
  docker rm -f "$cid" 2>/dev/null
done

# Remove docker image on uninstalling & updating
echo "glance-adm: Removing docker image"
echo "glance-adm: Image ID: $GLANCE_IMAGE"
if [ -n "$GLANCE_IMAGE" ]; then
  docker rmi -f "$GLANCE_IMAGE"
fi

exit 0
