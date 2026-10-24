#!/bin/bash
# Copies the test CA, OCSP and TSA certificates from the running ca container
# to the certs directory in the repo root. The certificates are generated when
# the ca-data volume is first initialized, so run this again after recreating
# the volume.
set -euo pipefail

CONTAINER=ca
DEST="$(cd "$(dirname "$0")/.." && pwd)/certs"

if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" != "true" ]; then
  echo "Container '$CONTAINER' is not running. Start it with: docker compose up -d $CONTAINER" >&2
  exit 1
fi

mkdir -p "$DEST"

for cert in ca ocsp tsa; do
  docker cp -q "$CONTAINER:/home/ca/CA/certs/$cert.cert.pem" "$DEST/$cert.pem"
  echo "Copied $cert.pem to $DEST"
done
