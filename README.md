yourbase
========

[![Slack Status](http://slack.yourbase.io/badge.svg)](http://slack.yourbase.io)

Community
=========

[Join the community slack](http://slack.yourbase.io).

Getting Started
===============

First install bazel

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

You can use the `bazel run` command for that. We can't do multiple bazel operations at once, that's why we cannot do `bazel run` for the server and the client at the same time.

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

Conformance tests
-----------------

The example server above is a `go_http_server` so we automatically enable uniformity tests for it. You can run them like this:

```
$ bazel test $(bazel query //examples/hellohttp/server/...|grep uniformity_test)

```

Troubleshooting
---------------

-	Repos in the Go code and shell scripts are cloned using `https` not `ssh`. Make sure your personal token is setup through the command line. This token is required if you are using 2FA on github with `https`. See [Setting up 2FA](https://help.github.com/articles/providing-your-2fa-authentication-code/#through-the-command-line) through command line.
