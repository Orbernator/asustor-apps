#!/bin/sh

echo "romm-adm: --== pre-uninstall ==--"

# Environment variables
ROMM_VERSION=$(cat $APKG_PKG_DIR/romm_version)
LINKWARDEN_CONTAINER=$(docker container ls -a | grep -E 'romm-db|romm' | awk '{print $1}')
ROMM_NETWORKS=$(docker network ls | grep romm | awk '{print $1}')
ROMM_IMAGE=$(docker images | grep rommapp/romm | grep $ROMM_VERSION | awk '{print $3}')
MARIA_IMAGE=$(docker images | grep mariadb | grep latest | awk '{print $3}')

# Force shutdown of the containers and delete them
echo "linkwarden-adm: Stopping and removing containers"
for cid in $LINKWARDEN_CONTAINER; do
  echo "    - $cid"
  docker kill "$cid" 2>/dev/null
  docker rm -f "$cid" 2>/dev/null
done


# Remove docker image on uninstalling & updating
echo "romm-adm: Removing docker image"
echo "romm-adm: Image ID: $ROMM_IMAGE"
if [ -n "$ROMM_IMAGE" ]; then
  docker rmi -f "$ROMM_IMAGE"
fi
echo "romm-adm: Image ID: $MARIA_IMAGE"
if [ -n "$MARIA_IMAGE" ]; then
  docker rmi "$MARIA_IMAGE"
fi

echo "romm-adm: Removing networks"
if [ -n "$ROMM_NETWORKS" ]; then
  docker network rm "$ROMM_NETWORKS"
fi

exit 0
