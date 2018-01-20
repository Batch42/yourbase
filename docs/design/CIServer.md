CI server
=======

CI server builds and tests code on demand when triggered by GitHub hooks (and maybe slack commands).

User Journey
------------

User commits her changes and pushes them to a development branch. All tests on her code tree are automatically run and she can see the results in a test results UI, linked from GitHub.

She then asks for a peer review and the code is merged into the master branch. Tests are run again. If any test fails, Jessica receives a warning about post-merging test failures.

Event Trigger
-------------

-	Code pushed to a branch
-	UI manually triggered

### Setup hooks for a user's repository

-	Register hook correctly:
	-	right bot destination address (one bot per user? or global bot?)
	-	secret specified on a per-customer basis, otherwise one customer could forge hook events for another customer
	-	Alternatives:
		1.	CLI securely send secret to us and we have to store it so we can check the secret
		2.	Leave the github hook registration to the server side. User sends us their github key. Gives us the flexibility to do other github operations in the future. But then we have to worry more about people's github keys. Also much more code.

<pre>
$ yb setup-repo https://github.com/me/myproject
  Cloning repo into "myproject"
  Checking Bazel workspace... missing.

  Would you like to add "WORKSPACE" and
    "BUILD.bazel" to your repository root so you can
    start building your code with Bazel? (Y/n): Y

  Files added. Git change committed and pushed:
    379c2ad51e756c9c69c2390c45bd02317e2320a0

  Checking CI hook... not found.

  Would you like to add a hook to your GitHub
   repository to build and test your code when branches
   are updated (Y/n): Y

  Repo setup done.
</pre>

Prototype:

<pre>
#!/bin/bash

set -eux

#my_external_ip="$(curl -s https://api.ipify.org)"
my_external_ip="bentobot.gkv.io"
repo=$1
hook=$2

. ~/.secrets/testenv

ngrok http 4657
=> get the $external_url

curl -v -X POST "https://api.github.com/repos/${repo}/hooks" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -d@- &lt;&lt;JSON
      { "name": "web", "active": true, "events": [ "push" ], "config": {
        "url": "${external_url}/postreceive",
        "content_type": "json",
        "secret": "&lt;something here&gt;",
        "insecure_ssl": "1"
      }}
JSON
</pre>

TODO: hookserve doesn't understand ping events, so github hook testing fails.

### Hook Handler server

-	Receive github hook events.
-	Checks the user's secret in the incoming github request
-	Run with high reliability - always give some result something even if the underlying operations fail.
-	SSL for all traffic
-	Support different customers in isolation [v2+]

Options:

<table>
<tr>
    <th>Name</th><th>URL</th><th>Notes</th>
</tr>
<tr>
    <td>adnanh's webhook</td>
    <td>https://github.com/adnanh/webhook</td>
    <td>Used it successfully before but not a library.</td>
</tr>
<tr>
    <td>hookserve</td>
    <td>https://github.com/phayes/hookserve</td>
    <td>Seems legit. Perhaps GitHub only?</td>
</tr>
<tr>
    <td>go-playground's webhooks</td>
    <td>https://github.com/go-playground/webhooks</td>
    <td>Supports gitlab too. Scary casting code.</td>
</tr>
</table>

Currently inclined to go with phayes'.

Input
-----

GitHub hook events containing:

-	Repo being changed
-	ID of the commit being changed
-	Source tree must contain Bazel targets
-	What targets to build/test would be determined automatically
	-	TODO: Allow specification of targets.

Process
-------

Determine what Operations should be run for that event and repo/commit, then run them.

#### Find affected targets

We assume usage of Bazel in the repo, so we can find all tests by looking for all files that changed recently and constructing a list of relevant targets. Perhaps for v1, we'll just run all tests under the tree.

But later we should use https://github.com/bazelbuild/bazel/blob/master/scripts/ci/ci.sh to find affected tests.

#### Run test targets

Under the hood, CI server is simple job scheduler. It shouldn't know about a repo's build environment. It starts a job that sets up or enters a working build environment.

##### Build environment, aka workspace

For us, a build environment is probably going to be a trivial docker container with Bazel pre-installed and with access to a cache to speed up the work.

Side note: An alternative is to consider the CI server just a remote execution forwarder. That is: receive the hook events, find the right targets (may require access to the build environment) then trigger a remote execution of them. See: https://github.com/bazelbuild/bazel/blob/master/src/main/java/com/google/devtools/build/lib/remote/README.md. Unfortunately this isn't really ready to use right now so we'll have to come up with a solution.

I don't believe there will be ready solutions for this out there because nobody initially will build this in a way that needs isolation between customers. So we shouldn't keep our hopes up about reusing something forever.

How our build environment will work:

-	All builds will be run as kubernetes jobs. Lets us use scheduling, reuse logging tools etc.
-	Jobs run as little containers that have our "build environment". Initially the `insready/bazel` image could be sufficient.
-	Each repository will have N volumes that allow us to speed up the bazel setup process (more below).
-	We'll control the scale of each repository (or workspace) build environment, but it should be easy to increase the number of nodes/volumes that can build each repo stuff.

I wish this was simpler but I can't think of a better way to deal with the stateful nature of the build environment. There's an opportunity for us to reuse best practices and expertise from other folks building CIs on kubernetes. There's also an opportunity for making a monster like this that generates value: https://github.com/kubernetes/test-infra/blob/master/docs/architecture.svg.

Side note: We may want to consider using other CI, but I wonder if they'll really help with our unique Bazel setup or just help with the easy parts. Besides, they are expensive.

##### Workspace Persistent Volume

-	Each repository will have N volumes that allow us to speed up the bazel setup process.
-	Each volume can only be used by one node at a time, because they will be modifying it (e.g: to advance commit versions, log stuff etc). It looks like kubernetes volume claims can be used for this.
-	For the Phase 1 we should probably use GCS persistent storage, though for this use case local volumes are not that bad because the impact of data loss is minimal. I think it's OK for us to use local volumes when we run in DigitalOcean and less sophisticated IaaS.

##### Kubernetes Control

How to control the kubernetes system without needing a bunch of stupid scripts? See KubernetesControl.md.

##### Other actions

For now, CI server will only do test runs.

Future versions should allow the user to specify more custom actions. But perhaps the best way to support this is to make it easy for users to create their own working webhooks.

Output
------

-	For each Operation, show programmatic-friendly results as:
	-	Operation status
	-	Logs
-	Allow incremental result streaming (e.g: observe logs in UI)

### Send status to GitHub commit status API


- Reference: https://developer.github.com/v3/repos/statuses/. 
- When there a push to a branch, trigger a build+test run and show the status: pending, failed, success.
- Make the status point to a URL with that specific build log.

### Show results in a web UI with logs

Currently stored on docker container output. Send container logs to logz.io ?

Prototype: 3 days (receive github hooks, run tests)
---------------------------------------------

-	Just a simple web server using phayes' library that logs stuff to ELK or to a blob store of some kind.
-	Make the UI a little less ugly.

