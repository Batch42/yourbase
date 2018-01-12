#!/bin/bash

# This is a quick test for HTTP servers. It assumes that the server is running
# on port 8080 and that it responds with status 200 to requests on /.

# Note: This is a proof of concept, it's unlikely to be useful for real use cases.

set -eu

server_binary="$1"

echo "BINARY: $server_binary"

# Send it to the background. Because we're not doing "disown", that child will
# automatically killed once this script exits.
"${server_binary}" &

# Wait a bit because the server may take a while to come up.
# TODO: Wait for the server to come up in a more robust way - like polling
# until it passes a healthcheck.
sleep 2

# TODO: Healthcheck before sending this.
# TODO: There's nothing wrong with 8080 being a conventional standard port for
# HTTP servers, but that value should be defined in a constant somewhere, or at
# least clearly documented.
curl -sS -fail http://localhost:8080/
