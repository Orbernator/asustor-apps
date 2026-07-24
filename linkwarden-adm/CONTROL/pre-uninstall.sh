#!/bin/sh

echo "linkwarden-adm: --== pre-uninstall ==--"

# Environment variables
LINKWARDEN_VERSION=$(cat $APKG_PKG_DIR/linkwarden_version)
LINKWARDEN_CONTAINER=$(docker container ls -a | grep -E 'linkwarden-db|linkwarden' | awk '{print $1}')
LINKWARDEN_NETWORKS=$(docker container ls -a | grep linkwarden | awk '{print $1}')
LINKWARDEN_IMAGE=$(docker images | grep linkwarden/linkwarden | grep $LINKWARDEN_VERSION | awk '{print $3}')
LINKWARDEN_DB_IMAGE=$(docker images | grep postgres | grep 15-alpine | awk '{print $3}')

# Force shutdown of the containers and delete them
echo "linkwarden-adm: Stopping and removing containers"
for cid in $LINKWARDEN_CONTAINER; do
  echo "    - $cid"
  docker kill "$cid" 2>/dev/null
  docker rm -f "$cid" 2>/dev/null
done

# Remove docker image on uninstalling & updating
echo "linkwarden-adm: Removing docker image"
echo "linkwarden-adm: Image ID: $LINKWARDEN_IMAGE"
if [ -n "$LINKWARDEN_IMAGE" ]; then
  docker rmi -f "$LINKWARDEN_IMAGE"
fi
echo "linkwarden-adm: Image ID: $LINKWARDEN_DB_IMAGE"
if [ -n "$LINKWARDEN_DB_IMAGE" ]; then
  docker rmi "$LINKWARDEN_DB_IMAGE"
fi

echo "linkwarden-adm: Removing networks"
if [ -n "$LINKWARDEN_NETWORKS" ]; then
  docker network rm "$LINKWARDEN_NETWORKS"
fi

exit 0
