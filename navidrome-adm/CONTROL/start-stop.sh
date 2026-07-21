#!/bin/sh

# Environment variable
NAVIDROME_CONTAINER='Navidrome'

case "$1" in
  start)
    # Starting navidrome
    echo "navidrome-adm: Starting service..."
    docker start $NAVIDROME_CONTAINER
    sleep 3
    ;;
  stop)
    # Stopping navidrome
    echo "navidrome-adm: Stopping service..."
    docker stop $NAVIDROME_CONTAINER
    sleep 3
    ;;
  reload)
    # Reloading navidrome
    echo "navidrome-adm: Reloading service..."
    docker stop $NAVIDROME_CONTAINER
    sleep 6
    docker start $NAVIDROME_CONTAINER
    sleep 3
    ;;
  *)
    echo "usage: $0 {start|stop|reload}"
    exit 1
    ;;
esac

exit 0
