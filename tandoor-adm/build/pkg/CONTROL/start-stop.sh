#!/bin/sh

# Environment variable
TUNARR_CONTAINER='Tunarr'

case "$1" in
  start)
    # Starting tunarr
    echo "tunarr-adm: Starting service..."
    docker start $TUNARR_CONTAINER
    sleep 3
    ;;
  stop)
    # Stopping tunarr
    echo "tunarr-adm: Stopping service..."
    docker stop $TUNARR_CONTAINER
    sleep 3
    ;;
  reload)
    # Reloading tunarr
    echo "tunarr-adm: Reloading service..."
    docker stop $TUNARR_CONTAINER
    sleep 6
    docker start $TUNARR_CONTAINER
    sleep 3
    ;;
  *)
    echo "usage: $0 {start|stop|reload}"
    exit 1
    ;;
esac

exit 0
