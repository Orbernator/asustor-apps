#!/bin/sh

echo "youtarr-adm: --== pre-uninstall ==--"

# Environment variables
YOUTARR_CONTAINERS=$(docker container ls -a | grep -E '^youtarr$|^youtarr-db$' | awk '{print $1}')

# Force shutdown of the containers and delete them
echo "youtarr-adm: Stopping and removing containers"
for cid in $YOUTARR_CONTAINERS; do
  echo "    - $cid"
  docker kill "$cid" 2>/dev/null
  docker rm -f "$cid" 2>/dev/null
done

# Remove docker images on uninstalling
echo "youtarr-adm: Removing docker images"
docker rmi -f dialmaster/youtarr:$(cat $APKG_PKG_DIR/youtarr_version 2>/dev/null) 2>/dev/null || true
docker rmi -f mariadb:10.3 2>/dev/null || true

# Optional: Remove volumes (comment out if you want to preserve data)
# docker volume rm youtarr-docker_youtarr-data 2>/dev/null || true
# docker volume rm youtarr-docker_db-data 2>/dev/null || true

exit 0
