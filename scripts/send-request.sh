#!/bin/bash
# Runs curl in a container so that it doesn't need to be installed locally.
# All arguments are passed to curl as-is. The progress meter is hidden by
# default, because the container has no terminal and curl would always show
# it; pass --progress-meter to show it. The current directory is mounted as
# the working directory, so files under it can be referenced with relative
# paths (e.g. -d @getRandom.xml). The container is attached to the
# xroad-network, so the workshop servers can be reached by their container
# names (e.g. http://ss2:8080) in addition to external hosts.
#
# JSON and XML responses are pretty-printed by format-response.py, which also
# runs in a container. Pass --raw as the first argument to print the response
# as received.
#
# Example:
#   cd requests
#   ../scripts/send-request.sh -d @getRandom.xml --header "Content-Type: text/xml" -X POST http://ss2:8080
set -euo pipefail

CURL_IMAGE=curlimages/curl:8.11.1
PYTHON_IMAGE=python:3.13.1-alpine
NETWORK=xroad-network
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

curl_in_container() {
  docker run --rm -i \
    --network "$NETWORK" \
    --user "$(id -u):$(id -g)" \
    -v "$PWD:/work" \
    -w /work \
    "$CURL_IMAGE" --no-progress-meter "$@"
}

if [ "${1:-}" = "--raw" ]; then
  shift
  curl_in_container "$@"
  exit
fi

curl_in_container "$@" | docker run --rm -i \
  --network none \
  -v "$SCRIPT_DIR/format-response.py:/format-response.py:ro" \
  "$PYTHON_IMAGE" python -I /format-response.py
