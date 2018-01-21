Release and Deploy
==================

### Example User Story

Once the new service is merged into master, a continuous deployment pipeline is automatically setup. All service environments are registered and available for service discovery.

Since the user decided to make this service available externally, a public URL is automatically created for the staging and development instances.

This service should only be used by the company's own clients (javascript broser clients and CLI), the user enabled auth enforcement for this service. The reverse proxy will only forward requests that contain valid application and user credentials in the gRPC call.

UX
==

Some UI shared with CI Server for sure, but not sure what.

Consider making this a CLI first since it's easier to iterate.

Most of the time the user wouldn't need to look at the release UI since things should happen automatically.

But we need at the very least:

-	A central UI where the user can list all releases for a service, and whether they are running in certain environments or not, when they were built, etc.
-	A per-release UI that shows details about what's happening to that release.
	-	Show its config.
	-	Show its build history and output.
	-	Show the attempts to deploy it to various environments.
	-	Show operator actions on it.
	-	Show URLs mapped to this release (ephemeral since it's per environment)
	-	Give user the ability to make changes to the release, like cherrypick a change or so (requires research)

*RESEARCH*: Check how people want to deal with cherrypicking / how to change releases.

Reverse Proxy
=============

Proxy rules could be implicit based on service + environment name. So no need to do service by service config. Eventually this won't suffice but should be good enough for some time.

-	Needs HTTPS.
-	Needs proxying headers.
-	Follow the deployment method accordingly (send traffic to healthy and ready tasks).

### Prototype: 2 days (revproxy)

-	Either use the httputil one (see clarice), which we'll have a lot of control over, but it won't be fully featured.
-	or use a kubernetes one, often specific to cloud providers.

If we were to use a custom one, how would it look?

-	Normal go_http_server server like everything else, but with custom k8s config to get it exposed. see kubefuncrunner, https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services---service-types and https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/.
-	advantage of being cloud neutral
-	also could support our fancy auth enforcement
-	but would still have many IPs. Probably a good idea to create a pool of such nodes so we sort of know their IPs, at least manage them separately.

<pre>
    serviceSpec.Spec.Type = v1.ServiceTypeNodePort
    serviceSpec.Spec.Ports[0].NodePort = 30001
</pre>

### out of scope gRPC proxying

proxying gRPC is a different thing. If needed, we can use: https://github.com/mwitkow/grpc-proxy

Release
=======

"Releasing" is to build a deployable artifact and get it ready for promotion and deployment.

-	build release on demand or by schedule.
	-	v1: when master branch is updated, create a new release. Only work on one release at a time and always resume building releases using the real most recent commit.
-	Later: rate limit the number of releases per hour/days
-	Upload it to a container registry or so, so we can fetch it from other machines
-	Make things consistent: a release has a specific digest and we'll use it throughout - don't use moving labels.

### Prototype: 3 days (build release after master push) *IN PROGRESS*

-	build release after each master push.
-	find go_server(s)
	-	`bazel query "filter('_image_publish$', attr(generator_function, go_http_server, ...))"`
	-	asked how to improve here: https://stackoverflow.com/questions/47495486/use-a-bazel-a-bazel-query-as-a-build-shortcut
-	publish a container image for it.

	-	use Bazel's container_push and send this to a private registry, otherwise it's almost impossible to get a container to run on k8s (would need the image cached on all target nodes..)
	-	for kubernetes instructions with private registries, see https://kubernetes.io/docs/concepts/containers/images/.

	-	no new UI but let people browse container images

	-	how to retrieve current images from the CLI

	```
	$ gcloud container images list
	NAME
	gcr.io/deft-cove-184100/bababot_server_image
	gcr.io/deft-cove-184100/hello_server_image
	gcr.io/deft-cove-184100/testing
	gcr.io/deft-cove-184100/zurigo_server_image
	```

	-	have another job that moves labels around
	-	and another job that deploys them

<pre>
go_image(
    name = "helloworld_image",
    importpath = "github.com/btreestudio/helloworld",
    library = ":go_default_library",
    visibility = ["//visibility:public"],
)

# To test the image from OSX:
bazel run --cpu=k8 :helloworld_image
</pre>

##### Using a Private Docker Registry

Google's seems like the best way to start for us. Our test k8s are in GCP anyway, so might as well benefit from the free network transfers.

<pre>
$ blaze run //server:zurigo_server_image_publish
INFO: Found 1 target...
Target //server:zurigo_server_image_publish up-to-date:
  bazel-bin/server/zurigo_server_image_publish
INFO: Elapsed time: 0.389s, Critical Path: 0.01s

INFO: Running command line: bazel-bin/server/zurigo_server_image_publish
gcr.io/deft-cove-184100/zurigo_server_image:{BUILD_USER} was resolved to gcr.io/deft-cove-184100/zurigo_server_image:yves
gcr.io/deft-cove-184100/zurigo_server_image:yves was published with digest: sha256:59806f5bf47a5c2f06535d25a68a6b72c316a1dadbcc5e9660d7e847c0891e66
</pre>

We may need to authenticate to GCR in order to pull and push our images. We'll use service accounts for that.

See:

-	https://cloud.google.com/container-registry/docs/advanced-authentication
-	https://support.google.com/cloud/answer/6158849#serviceaccounts

Promotion
=========

Pipeline for promotion to other environments

-	Based upon certain conditions and schedule, get a release from early stage to later stage
-	Make sure it's a promotion, not a deployment of a new unused release
-	Promote new releases to an autopush kind of environment
-	Update the monitoring to make sure it's querying this new environment+environment and/or the individual running co
-	Allow rollbacks

### Prototype: 4 days (CLI to promote releases)

-	simplest of CLI, UI or slackbot for promoting.
-	no checks, no nothing. just: deploy release Foo to environment X.
	-	maybe it's a bazel target: `bazel run --action_env=ENV=dev helloworld:helloworld_server_deploy`

Deployment
==========

A/B, green etc. See references below.

*RESEARCH*: Find Phase 1-friendly version.

Allow rollbacks

### Prototype: 1 day

-	Just deploy k8s deployment using create-or-update semantics.
-	XXX OR JUST CONSIDER SPINNAKER FOR NOW https://github.com/kubernetes/charts/tree/master/stable/spinnaker

Auth
====

This is on this document because it's related to the reverse proxy. The dream is to inspect gRPC credentials in a generic way so we can see if the user is authorized to make calls to this environment (how? I think I wrote notes about this somewhere).

If a user tries to visit a restricted environment they don't get access to, treat it as if that environment didn't exist (404).

### Prototype: 3 days maybe (auth for dev/staging environments)

-	a few hours to check if this is possible, then implement into the proxy.
-	remember gRPC isn't usable by browsers yet.

Architecture
============

#### Thoughts

-	terraform you statically represent your goal infrastructure. It helps with templates and making things high-level. But the focus is on static intent representation of stuff, so it's easy to review, maintain etc.
	-	but you gotta use Jenkins to actually do things like deploying your app. Terraform is about infra, not the app.
-	spinnaker gets the app and deploy into prod.

What we want is a very dynamic feedback loop. We only should define:

-	high-level service objectives
-	sensors about the infra performance and sub-problems
-	control mechanisms for changing the system behavior based on observed signals.

Spinnaker Experiments
=====================

Should we use spinnaker? It looks decent, has a difficult setup (good and bad) but has a lot of pluggability. Could be an asset.

-	docker GCR setup https://www.spinnaker.io/setup/providers/docker-registry/
-	how to make spinnaker publicly accessible with oauth2 https://www.spinnaker.io/setup/quickstart/halyard-gke-public/
-	spinnaker heml (works very well for initial setup) https://github.com/kubernetes/charts/tree/master/stable/spinnaker

References
==========

-	[Deployment Strategies](https://thenewstack.io/deployment-strategies/) - Discusses A/B, Green, Shadow, Canary etc.
