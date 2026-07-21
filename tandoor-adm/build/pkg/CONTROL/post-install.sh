#!/bin/sh

echo "tunarr-adm: --== post-install ==--"

# Environment variables
TUNARR_VERSION=$(cat $APKG_PKG_DIR/tunarr_version)
TUNARR_DATA_PATH='/share/Docker/Tunarr'
TUNARR_CONTAINER='Tunarr'

# Ensure data directory exists
mkdir -p "$TUNARR_DATA_PATH"

# Pull the container image
echo "tunarr-adm: Fetching data"
docker pull chrisbenincasa/tunarr:$TUNARR_VERSION

# Installing creating container
echo "tunarr-adm: Creating container"
if [ -e /dev/dri ]; then
  docker create -i -t --name=$TUNARR_CONTAINER \
    --publish 8000:8000 \
    --env TUNARR_LOG_LEVEL=INFO \
    --restart=unless-stopped \
    --volume $TUNARR_DATA_PATH:/config/tunarr \
    --volume /share:/share:ro \
    --volume /etc/localtime:/etc/localtime:ro \
    --device /dev/dri:/dev/dri \
    chrisbenincasa/tunarr:$TUNARR_VERSION
else
  docker create -i -t --name=$TUNARR_CONTAINER \
    --publish 8000:8000 \
    --env TUNARR_LOG_LEVEL=INFO \
    --restart=unless-stopped \
    --volume $TUNARR_DATA_PATH:/config/tunarr \
    --volume /share:/share:ro \
    --volume /etc/localtime:/etc/localtime:ro \
    chrisbenincasa/tunarr:$TUNARR_VERSION
fi

echo "tunarr-adm: Installation/Update complete"

# Starting container
echo "tunarr-adm: Starting container"
docker start $TUNARR_CONTAINER

exit 0
