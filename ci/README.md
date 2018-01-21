# CI

# Setup

## Secrets
Place secrets in a `github.jsonnet` file in /secrets/ on your local filesystem. That path can be changed what's in the WORKSPACE file. Example:

```
$ cat /secrets/github.jsonnet 
{
	"username": std.base64("nictuku"),
	"password" : std.base64("password here"),
	"token" : std.base64("github token here")
}
```

Deploy the secrets to your kubernetes namespace:

```
$ bazel run //ci:ci_server_deploy_secret_github.apply
# ...
(00:00:51) INFO: Running command line: bazel-bin/ci/ci_server_deploy_secret_github.apply
secret "github" created
```

## Deploy the CI

```
$ bazel run --experimental_platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //ci:ci_server_deploy.apply
```

Run a live test and check the log output. The CI build should generate a _failure_ (that's on purpose).

```
$ bash ci/tools/live_test.sh
$ bash ci/tools/logs.sh
# or
$ bash ci/tools/check_status.sh
```

## Check the kibana logs

Do the k8s port forward first (see the LoggingInfrastructure doc). Then head to the kibana dashboard at http://localhost:5601/ and search for "commit".

TODO: make this nicer.

Note: The CI logs aren't generating a logstash-friendly output. We gotta fix that.

