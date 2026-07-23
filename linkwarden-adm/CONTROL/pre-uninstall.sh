#!/bin/sh

echo "linkwarden-adm: --== pre-uninstall ==--"

# Environment variables
LINKWARDEN_CONTAINERS=$(docker container ls -a | grep -E '^linkwarden$|^linkwarden-db$' | awk '{print $1}')

# Force shutdown of the containers and delete them
echo "linkwarden-adm: Stopping and removing containers"
for cid in $LINKWARDEN_CONTAINERS; do
  echo "    - $cid"
  docker kill "$cid" 2>/dev/null
  docker rm -f "$cid" 2>/dev/null
done

# Remove docker images on uninstalling
echo "linkwarden-adm: Removing docker images"
docker rmi -f ghcr.io/linkwarden/linkwarden:$(cat $APKG_PKG_DIR/linkwarden_version 2>/dev/null) 2>/dev/null || true
docker rmi -f postgres:15-alpine 2>/dev/null || true

# Optional: Remove volumes (comment out if you want to preserve data)
# docker volume rm linkwarden-docker_linkwarden-data 2>/dev/null || true
# docker volume rm linkwarden-docker_db-data 2>/dev/null || true

exit 0
