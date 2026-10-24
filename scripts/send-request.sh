#!/bin/bash
# Runs curl in a container so that it doesn't need to be installed locally.
# All arguments are passed to curl as-is. The current directory is mounted as
# the working directory, so files under it can be referenced with relative
# paths (e.g. -d @getRandom.xml). The container is attached to the
# xroad-network, so the workshop servers can be reached by their container
# names (e.g. http://ss2:8080) in addition to external hosts.
#
# Example:
#   cd requests
#   ../scripts/send-request.sh -d @getRandom.xml --header "Content-Type: text/xml" -X POST http://ss2:8080
set -euo pipefail

CURL_IMAGE=curlimages/curl:8.11.1
NETWORK=xroad-network

exec docker run --rm -i \
  --network "$NETWORK" \
  --user "$(id -u):$(id -g)" \
  -v "$PWD:/work" \
  -w /work \
  "$CURL_IMAGE" "$@"
