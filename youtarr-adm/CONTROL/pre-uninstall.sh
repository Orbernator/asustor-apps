#!/bin/sh

echo "youtarr-adm: --== pre-uninstall ==--"

# Environment variables
YOUTARR_VERSION=$(cat $APKG_PKG_DIR/youtarr_version)
YOUTARR_CONTAINERS=$(docker container ls -a | grep -E 'youtarr|youtarr-db' | awk '{print $1}')
YOUTARR_IMAGE=$(docker images | grep dialmaster/youtarr | grep $YOUTARR_VERSION | awk '{print $3}')
YOUTARR_IMAGE=$(docker images | grep mariadb | grep 10.3 | awk '{print $3}')
YOUTARR_NETWORKS=$(docker container ls -a | grep youtarr | awk '{print $1}')
# Force shutdown of the containers and delete them
echo "youtarr-adm: Stopping and removing containers"
for cid in $YOUTARR_CONTAINERS; do
  echo "    - $cid"
  docker kill "$cid" 2>/dev/null
  docker rm -f "$cid" 2>/dev/null
done

# Remove docker images on uninstalling
echo "youtarr-adm: Removing docker image"
echo "youtarr-adm: Image ID: $YOUTARR_IMAGE"
if [ -n "$YOUTARR_IMAGE" ]; then
  docker rmi -f "$YOUTARR_IMAGE"
fi

echo "youtarr-adm: Removing docker image"
echo "youtarr-adm: Image ID: $YOUTARR_DB_IMAGE"
if [ -n "$YOUTARR_DB_IMAGE" ]; then
  docker rmi "$YOUTARR_DB_IMAGE"
fi

echo "youtarr-adm: Removing networks"
if [ -n "$YOUTARR_NETWORKS" ]; then
  docker network rm "$YOUTARR_NETWORKS"
fi

# Optional: Remove volumes (comment out if you want to preserve data)
# docker volume rm youtarr-docker_youtarr-data 2>/dev/null || true
# docker volume rm youtarr-docker_db-data 2>/dev/null || true

exit 0
