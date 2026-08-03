#!/bin/sh

echo "music_assistant-adm: --== pre-uninstall ==--"

# Environment variables
MUSIC_ASSISTANT_VERSION=$(cat $APKG_PKG_DIR/musicassistant_version)
MUSIC_ASSISTANT_CONTAINER=$(docker container ls -a | grep -E 'music-assistant' | awk '{print $1}')
MUSIC_ASSISTANT_NETWORKS=$(docker container ls -a | grep music-assistant | awk '{print $1}')
MUSIC_ASSISTANT_IMAGE=$(docker images | grep ghcr.io/music-assistant/server | grep $MUSIC_ASSISTANT_VERSION | awk '{print $3}')

# Force shutdown of the containers and delete them
echo "music_assistant-adm: Stopping and removing containers"
for cid in $MUSIC_ASSISTANT_CONTAINER; do
  echo "    - $cid"
  docker kill "$cid" 2>/dev/null
  docker rm -f "$cid" 2>/dev/null
done

# Remove docker image on uninstalling & updating
echo "music_assistant-adm: Removing docker image"
echo "music_assistant-adm: Image ID: $MUSIC_ASSISTANT_IMAGE"
if [ -n "$MUSIC_ASSISTANT_IMAGE" ]; then
  docker rmi -f "$MUSIC_ASSISTANT_IMAGE"
fi

echo "music_assistant-adm: Removing networks"
if [ -n "$MUSIC_ASSISTANT_NETWORKS" ]; then
  docker network rm "$MUSIC_ASSISTANT_NETWORKS"
fi

exit 0
