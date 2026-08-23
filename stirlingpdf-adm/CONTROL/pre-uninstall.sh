#!/bin/sh

echo "stirlingpdf-adm: --== pre-uninstall ==--"

# Environment variables
STIRLINGPDF_VERSION=$(cat $APKG_PKG_DIR/stirlingpdf_version)
STIRLINGPDF_CONTAINERS=$(docker container ls -a | grep -E 'stirlingpdf' | awk '{print $1}')
STIRLINGPDF_IMAGE=$(docker images | grep docker.stirlingpdf.com/stirlingtools/stirling-pdf | grep $STIRLINGPDF_VERSION | awk '{print $3}')
STIRLINGPDF_NETWORKS=$(docker container ls -a | grep stirlingpdf | awk '{print $1}')
# Force shutdown of the containers and delete them
echo "stirlingpdf-adm: Stopping and removing containers"
for cid in $STIRLINGPDF_CONTAINERS; do
  echo "    - $cid"
  docker kill "$cid" 2>/dev/null
  docker rm -f "$cid" 2>/dev/null
done

# Remove docker images on uninstalling
echo "stirlingpdf-adm: Removing docker image"
echo "stirlingpdf-adm: Image ID: $STIRLINGPDF_IMAGE"
if [ -n "$STIRLINGPDF_IMAGE" ]; then
  docker rmi -f "$STIRLINGPDF_IMAGE"
fi

echo "stirlingpdf-adm: Removing networks"
if [ -n "$STIRLINGPDF_NETWORKS" ]; then
  docker network rm "$STIRLINGPDF_NETWORKS"
fi

# Optional: Remove volumes (comment out if you want to preserve data)
# docker volume rm stirlingpdf-docker_stirlingpdf-data 2>/dev/null || true
# docker volume rm stirlingpdf-docker_db-data 2>/dev/null || true

exit 0
