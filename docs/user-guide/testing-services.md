Testing YourBase Services
=============================

If we want to make services easy to change, we need good tests that give us confidence that our changes are safe. These are our goals for tests in the platform:

-	**easy to create**: developers are more likely to create and maintain tests when it doesn't take a lot of effort to create tests.
-	**fast**: developers should be able to quickly run tests, change their code, then run tests again.
-	**reliable**: we should provide tools and infrastructure that helps developers avoid the creation of flaky tests.

YourBase comes with many simple built-in tests for all types of servers we support, including Go and nodeJS. It's also very easy to add new service-specific tests, as you'll find out.

### Small == Fast

Tests should be fast. They are used by developers when they are writing code or fixing bugs, so it's important that tests fail or pass quickly.

Users should rely on smaller tests for day-to-day work and leave larger tests for things like qualifying a release before promoting it to different environment.

It can be tempting to use large end-to-end tests for everything, but it's better to have redundant tests of different sizes than to rely solely on end-to-end tests. In extreme cases, large tests can take hours to run and failed tests can be extremely hard to debug.

Developers of microservices should also avoid depending on a large number of downstream microservices to test their service, and use test doubles as needed.

We will carefully monitor all tests run in the platform. We will selectively nudge users to use smaller tests or switch to test doubles for some heavier dependencies.

### Reliable

Flaky tests are a major cause of productivity loss.

We will help users identify flaky tests. Flakiness will be tracked and reported for all tests so teams know what to improve next.

In some cases we might be able to detect and check against flakiness before the code is submitted.

Built-in Tests
-----------------
Every server automatically gets a suite of tests that can run locally or in an hermetic remote environment and catch various issues:

* does the server startup within a reasonable amount of time?
* can the server respond to basic requests such as `HTTP/1.0 GET /` and server metadata requests?
* what are the UI deltas compared to the version in the master branch?

To find what tests are available, run:

{% method %}

{% sample lang="js" %}
```
$ bazel query //helloworld:all
nodejs_server 	//helloworld:nodejs_server
run 		//helloworld:nodejs_server_ui_diff
test		//helloworld:nodejs_server_smoke_test
test 		//helloworld:nodejs_server_start_test
```

{% sample lang="go" %}
```
$ bazel query   //helloworld:all
go_server 	//helloworld:go_server
run 		//helloworld:go_server_ui_diff
test		//helloworld:go_server_smoke_test
test 		//helloworld:go_server_start_test
```

You can run individual `_test` targets with:
{% sample lang="js" %}
```
$ bazel test //heloworld:nodejs_server_smoke_test
```

{% sample lang="go" %}
```
$ bazel test //heloworld:go_server_smoke_test
```
{% common %}
Or all of them!

```
$ bazel test //helloworld:...
```

Or run the all quick tests after every build (_quick_tests is an target group that combines all tests that can run quickly. Also note that we're using `ibazel` here, for incremental testing):

{% sample lang="js" %}
```
$ ibazel test //helloworld:nodejs_server_quick_tests
```

To run tests remotely, pass the --remote flag *after* the target name.

```
$ bazel test //helloworld:nodejs_server_smoke_test --remote
```

{% sample lang="go" %}
```
$ ibazel test //helloworld:go_server_quick_tests
```

To run tests remotely, pass the --remote flag *after* the target name.

```
$ bazel test //helloworld:go_server_smoke_test --remote
```

{% common %}

### Run the server with a test UI

```
$ bazel run //userevents:server_test_ui
Starting userevent server at http://localhost:9999
Starting test UI at http://localhost:8080/ui
```

TODO: insert screenshot with a test UI showing the UserEventService API and with forms for sending test queries to it..

```
$ bins/opt/grpc_cli call localhost:9999 Say.Hello "name: 'world'"
```

How to write service-specific test tests
------------------

{% sample lang="js" %}

`Shameful copy-paste from bazel/nodejs_rules here`

The jasmine_node_test rule can be used to run unit tests in NodeJS, using the Jasmine framework. Targets declared with this rule can be run with bazel test.

Attributes:

The srcs of a jasmine_node_test should include the test .js files. The deps should include the production .js sources, or other rules which produce .js files, such as TypeScript.

The examples/program/index.spec.js file illustrates this. Another usage is in https://github.com/angular/tsickle/blob/master/test/BUILD

{% sample lang="go" %}For Go, write your tests [as usual](https://golang.org/doc/code.html#Testing), then wire them up on Bazel using `gazelle`:

-	Create a `something_test.go` file with your unit-tests. For example (FIXME: this is copy-pasta from golang.org):

	```go
	package stringutil

	import "testing"

	func TestReverse(t *testing.T) {
		cases := []struct {
			in, want string
		}{
			{"Hello, world", "dlrow ,olleH"},
			{"Hello, 世界", "界世 ,olleH"},
			{"", ""},
		}
		for _, c := range cases {
			got := Reverse(c.in)
			if got != c.want {
				t.Errorf("Reverse(%q) == %q, want %q", c.in, got, c.want)
			}
		}
	}
	```

-	Run gazelle to automatically update the `BUILD.bazel` with the new test:

	```bash
	$ bazel run //:gazelle
	```

-	Take a look at the resulting `BUILD.bazel` section:

	```python
	go_test(
	   name = "go_default_test",
	    srcs = ["something_test.go"],
	    embed = [":go_default_library"],
	    importpath = "github.com/you/repo/code",
	)
	```

-	Run the test:

	```bash
	$ bazel test :all
	INFO: (12-20 12:57:05.909) Found 12 targets and 1 test target...
	//hellohttp/server:go_default_test        PASSED in 0.2s
	```

{% endmethod %}

Why is this better?
-------------------

Bazel adds extra steps to the Go testing process. But there are many upsides:

1. sanity tests for each language (Go, nodeJS, etc) and transport type (gRPC, HTTP) that work out-of-the-box.
1.	tests in different languages run the same way - no need to install other tools or explain to your team how to run them: it's always just `bazel test :foo`
2.	the code is ready to be tested by CIs that understand bazel
3.	if your tests are represented in the bazel graph, you can query your dependencies and reverse dependencies. For example, if you're changing a base library, you can *run all tests that indirectly depend on your library*, and increase your confidence on the change. If your tree has a reasonable size, this command returns all tests that depend on the target library: `bazel query 'tests(rdeps(..., //soccer/players:zico))'`

