YourBase, the development platform for growing teams
====================================================

[![Slack Status](http://slack.yourbase.io/badge.svg)](http://slack.yourbase.io)

YourBase is a fully automated delivery platform that enforces microservice best-practices. Our main goals:

-	Be very easy to get started.
-	Scale from small teams to large ones and perhaps help build the next Google or Facebook ;-).
-	Enforce uniformity between apps of the same type. (e.g: "Go REST API Server" or "Java Spring REST API Server") to simplify operations and debugging.

See [Getting Started](#getting-started) and the [User Guide](https://guide.yourbase.io) for details.

Roadmap
-------

### Phase 1 (In Progress)

-	CI: build and tests code on demand.
-	CD: continuous deployment pipeline that releases and deploys code to different stages.
-	Logging: collection, aggregation, searching and visualization.
-	Monitoring: metrics and alerting with support for external integrations.
-	Configuration uniformity for each type of application (e.g: different instances of <i>Java Sprint REST API Server</i> should have nearly identical setup.

### Phase 2

-	Tracing: correlation of events based on request traces.
-	Enforcement of best-practices:
	-	Prevent connections to un-managed resources.
	-	Check for sane distributed system practices: request retry logic; circuit breakers; health-checking.
	-	Setup loadtest with one command, and optionally require loadtests before rollout.

Community
=========

[Join the community slack](http://slack.yourbase.io).

Getting Started
===============

First, install Bazel ([requires Java](https://github.com/yourbase/yourbase/issues/7), for now):

```
$ brew install bazel
```

Build the HTTP server:

```
$ bazel build examples/hellohttp/server:server
```

Run it locally:

```
$ bazel-bin/examples/hellohttp/server/server
```

Now run the HTTP client.

You can use the `bazel run` command for that. We can not do multiple bazel operations at once, that's why we cannot do `bazel run` for the server and the client at the same time.

You can pass arguments to the target program by putting them after a `--` otherwise the arguments are interpreted as arguments to `bazel`.

```
$ bazel run //examples/hellohttp/client:client http://localhost:8080/
(20:20:49) INFO: Current date is 2018-01-11
(20:20:49) INFO: Analysed target //examples/hellohttp/client:client (0 packages loaded).
(20:20:49) INFO: Found 1 target...
Target //examples/hellohttp/client:client up-to-date:
  bazel-bin/examples/hellohttp/client/darwin_amd64_stripped/client
(20:20:50) INFO: Elapsed time: 0.893s, Critical Path: 0.02s
(20:20:50) INFO: Build completed successfully, 1 total action

(20:20:50) INFO: Running command line: bazel-bin/examples/hellohttp/client/darwin_amd64_stripped/client http://localhost:8080/
fetching http://localhost:8080/
Hello, World
```

The last line saying `Hello, World` is what we wanted. Great!

Uniformity tests
----------------

The example server above is a `go_http_server` so we automatically enable uniformity tests for it. You can run them like this:

```
$ bazel test --test_output=all $(bazel query //examples/hellohttp/server/...|grep uniformity_test)
INFO: From Testing //examples/hellohttp/server:go-hellohttp_uniformity_test
==================== Test output for //examples/hellohttp/server:go-hellohttp_uniformity_test:
Found framework of type GoApp
Fetching http://localhost:8080/
PASS
================================================================================
//examples/hellohttp/server:go-hellohttp_uniformity_test        (cached) PASSED in 2.2s

```

Troubleshooting
---------------

-	Repos in the Go code and shell scripts are cloned using `https` not `ssh`. Make sure your personal token is setup through the command line. This token is required if you are using 2FA on github with `https`. See [Setting up 2FA](https://help.github.com/articles/providing-your-2fa-authentication-code/#through-the-command-line) through command line.

Later
=====

-	CI
-	Deployment
-	Monitoring, etc

See Also
========

-	[User Guide](/docs/user-guide/README.md)
-	Blog Post: [Building a Fast Track for Software Development](https://yourbase.io/blog/a-fast-track-for-software-development/)
