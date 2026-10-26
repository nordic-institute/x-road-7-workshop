#!/bin/bash
# Empties the OCSP response cache of a Security Server container and makes the
# signer fetch new OCSP responses. Follows the NIIS Knowledge Base article
# "How to Empty the OCSP Cache on the Security Server", adapted to the Sidecar
# image, where the services run under supervisord instead of systemd.
#
# The cached responses are moved to /tmp/ocsp-cache-<timestamp> inside the
# container instead of being deleted.
#
# Usage: scripts/clear-ocsp-cache.sh <ss1|ss2>
set -euo pipefail

CACHE_DIR=/var/cache/xroad
WAIT_SECONDS=120

usage() {
  echo "Usage: $0 <ss1|ss2>" >&2
  exit 1
}

[ $# -eq 1 ] || usage
case "$1" in
  ss1 | ss2) CONTAINER="$1" ;;
  *) usage ;;
esac

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" != "true" ]; then
  echo "Container '$CONTAINER' is not running. Start it with: docker compose up -d $CONTAINER" >&2
  exit 1
fi

in_container() {
  docker exec "$CONTAINER" bash -c "$1"
}

count_responses() {
  in_container "ls $CACHE_DIR/*.ocsp 2>/dev/null | wc -l" | tr -d ' '
}

echo "$CONTAINER: $(count_responses) cached OCSP responses"

echo "$CONTAINER: stopping xroad-signer"
in_container "supervisorctl stop xroad-signer" >/dev/null

BACKUP_DIR="/tmp/ocsp-cache-$(date +%Y%m%d%H%M%S)"
in_container "mkdir -p $BACKUP_DIR && find $CACHE_DIR -maxdepth 1 -name '*.ocsp' -exec mv {} $BACKUP_DIR/ \;"
echo "$CONTAINER: moved the cached responses to $BACKUP_DIR"

echo "$CONTAINER: starting xroad-signer"
in_container "supervisorctl start xroad-signer" >/dev/null

echo "$CONTAINER: waiting for new OCSP responses (max ${WAIT_SECONDS}s)"
for ((i = 0; i < WAIT_SECONDS; i += 5)); do
  count=$(count_responses)
  if [ "$count" -gt 0 ]; then
    echo "$CONTAINER: $count new OCSP responses fetched"
    exit 0
  fi
  sleep 5
done

echo "$CONTAINER: no new OCSP responses after ${WAIT_SECONDS}s. Check the signer log: docker logs --tail 100 $CONTAINER" >&2
exit 1
