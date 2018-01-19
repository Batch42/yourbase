#/bin/bash

# Since this is an hermetic test, we can't use the local filesystem. So there's
# no caching and it will take a long time.
# Ideally we also want to speed this up because we care about the cold case.

set -eu

target_host="localhost:8080"
#target_host="$(kubectl get svc -n $USER ci-server-svc -o jsonpath="{.status.loadBalancer.ingress[*].ip}")"

# This should result in a test failure, but it doesn't because of:
# https://github.com/yourbase/yourbase/issues/15
#payload="$(dirname $0)/testdata/failure_payload.json"

server="$TEST_SRCDIR/__main__/$1"
output="$TEST_TMPDIR/ci-output.log"
$server -runOnce -tmpBase -testShell > $output 2>&1 &

server_pid=$!

# TODO: Wait properly.
sleep 5
payload="$(dirname $0)/testdata/failure_branch_payload.json"

curl -f \
	-H "content-type: application/json" \
	-H "User-Agent: GitHub-Hookshot/f2b2366" \
	-H "X-GitHub-Event: push" --data "@${payload}" http://${target_host}/postreceive
	# Not needed:
	# -H "X-GitHub-Delivery: 418f1f00-fcf7-11e7-9fba-db41916318a8" \
    # Currently not used because the CI server doesn't have a secret, yet.
	# The X-Hub-Signature is an HMAC hash of the secret and the payload.
	# -H "X-Hub-Signature: sha1=44c8e2f4ee2cb1a7667d82f741c8bbcdc4f8e6a8" \

# Since we're using failure_branch_payload.json, the build result should be a 
# failure.
set +e
wait $server_pid
result=$?
cat $output
if [[ $result -eq $0 ]]; then
  # Expected failure
  exit 1
fi