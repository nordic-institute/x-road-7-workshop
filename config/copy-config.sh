#!/bin/bash
# Copies the X-Road configuration files from the git repo (mounted read-only
# at /workshop/config) to /etc/xroad/conf.d on the first startup only and then
# runs the original image entrypoint given as the container command. Files
# missing from the repo are skipped. To copy the files again, delete the
# marker file and restart.
set -euo pipefail

SRC=/workshop/config
DEST=/etc/xroad/conf.d
MARKER=$DEST/.workshop-config-copied

if [ ! -f "$MARKER" ]; then
  mkdir -p "$DEST"
  for f in local.ini mail.yml acme.yml; do
    [ -f "$SRC/$f" ] || continue
    install -o xroad -g xroad -m 640 "$SRC/$f" "$DEST/$f"
    echo "$(date --utc -Iseconds) INFO [copy-config] Copied $f to $DEST"
  done
  touch "$MARKER"
fi

exec "$@"
