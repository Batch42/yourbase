#! /usr/bin/env bash

# This is YourBase's modified ci.sh that runs inside a CI container with access
# to a persistent caching volume.

#
# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# This script looks at the files changed in git against origin/master
# (actually a common ancestor of origin/master and the current commit) and
# queries for all build and test targets associated with those files.
#
# Running this script on a CI server should allow you to only test the targets
# that have changed since the last time your merged or fast forwarded.
#
# This script can be used to recreate the benefits that TAP provides to
# Google's developers as describe by Mike Bland on his article on Google's
# infrastructure.
# https://mike-bland.com/2012/10/01/tools.html#tools-tap-sponge
#
# "Every single change submitted to Google’s Perforce depot is built and
# tested, and only those targets affected by a particular change are
# built and tested"
#
# When this script is triggered by Gerrit's patchset-updated hook (for example)
# you can replace origin/master in the COMMIT_RANGE variable initialization
# with the branch passed as argument to the hook. When using Jenkins with the
# Gerrit Trigger Plugin, use $GERRIT_BRANCH instead. This would make it
# possible to have the Verified label on Gerrit patchsets populated as fast
# as possible.
# For a ref-updated event, use "${GERRIT_OLDREV}..${GERRIT_NEWREV}" as the
# value for COMMIT_RANGE.
# When running in Travis-CI, you can directly use the $TRAVIS_COMMIT_RANGE
# environment variable.


# For this to work on Travis, first we would need `git fetch origin master:refs/remotes/origin/master`
# But like said above, we can just use $TRAVIS_COMMIT_RANGE
#COMMIT_RANGE=${COMMIT_RANGE:-$(git merge-base origin/master HEAD)".."}
COMMIT_RANGE=${TRAVIS_COMMIT_RANGE:-$(git merge-base origin/master HEAD)".."}

if [[ -z ${COMMIT_RANGE} ]]; then
        echo "Could not find commit range." 2>&1 > /dev/null
	exit 1
fi

CACHE_DIR=${CACHE_DIR:-"$HOME/bazel-cache"}

function brun() {
    bazel \
        --output_user_root="$CACHE_DIR" \
        "$@"
}

# Go to the root of the repo
cd "$(git rev-parse --show-toplevel)"

# Get a list of the current files in package form by querying Bazel.
files=()
for file in $(git diff --name-only ${COMMIT_RANGE} ); do
  IFS=$'\n' read -r -a files <<< "$(brun query --noshow_progress $file)"
  brun query --noshow_progress $file
done

# Query for the associated buildables
buildables=$(brun query \
    --keep_going \
    --noshow_progress \
    "kind(.*_binary, rdeps(//..., set(${files[*]})))")
# Run the tests if there were results
if [[ ! -z $buildables ]]; then
  echo "Building binaries"
  brun build $buildables
fi

tests=$(brun query \
    --keep_going \
    --noshow_progress \
    "kind(test, rdeps(//..., set(${files[*]}))) except attr('tags', 'manual', //...)")
# Run the tests if there were results
if [[ ! -z $tests ]]; then
  echo "Running tests"
  brun test $tests
fi
