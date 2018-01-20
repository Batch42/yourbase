YourBase Phase 1
======

Bazel rules and environment that can be used for frictionless microservices development.

UX
--

### Development workstation setup

<pre>
$ wget yourbase.io/zli && install yb
$ yb init
  Downloading Bazel...
  Temp credentials stored in ~/.yb/credentials
</pre>

NOTE: temp credentials are for the remote build and execution service. It should be possible to exchange them for a permanent user setup. Alternative: github auth or so.

#### Prototype: 1 day

-	write clear instructions for installing Bazel and maybe why

### Repository setup

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

NOTE: Figure out what's the most natural way to do this. Perhaps do the WORKSPACE+BUILD thing as part of writing the code, but do the github hooking later so it's connected with the CI/CD stuff? Or it can be confusing.

NOTE2: Maybe this could be a bazel command? Why not be 100% consistent?

#### Prototype: 2 days (CLI to help setup a repo)

-	setup-repo command that clones, adds files, submits (handling errors and presenting friendly messages), checks for hook, adds hook

### userevents.proto

<pre>syntax = "proto3";

service UserEventService {
    rpc Track(EventRequest) returns (EventResponse) {}
}

message EventRequest {
    string ApplicationToken = 1;
    string UserToken = 2;

            string Source = 3;
            string EventType = 4;
            string EventDetails = 5;
}

message EventResponse {
}
</pre>

### Go gRPC server code

<pre>package main

import (
    "flag"
    "fmt"
    "log"
    "net"

    "google.golang.org/grpc"

    pb "github.com/btreestudio/examples/userevents"
    "golang.org/x/net/context"
)

var port = flag.Int("port", 9999, "Server port")

type Say struct{}

func (s *Say) Hello(ctx context.Context, req *pb.Request) (*pb.Response, error) {
    log.Print("Received Say.Hello request")
    rsp := &pb.Response{Msg: "Hello " + req.Name}
    return rsp, nil
}

func main() {
    flag.Parse()
    lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
    if err != nil {
        log.Fatalf("failed to listen: %v", err)
    }
    grpcServer := grpc.NewServer()
    pb.RegisterSayServer(grpcServer, new(Say))
    grpcServer.Serve(lis)
}
</pre>

### Build and Test

#### Generate BUILD.bazel files

<pre>
$ bazel run //:gazelle
</pre>

#### Run the server with a test UI

<pre>
$ bazel run //userevents:server_test_ui
Starting userevent server at http://localhost:9999
Starting test UI at http://localhost:8080/ui
</pre>

TODO: insert screenshot with a test UI showing the UserEventService API and with forms for sending test queries to it..

NOTE: UI thing would be a whole project. letmegrpc relies on gogo proto, and it's veeery early/fragile. This could be a good side project. This could be a good start: https://github.com/grpc/grpc-go/blob/master/Documentation/server-reflection-tutorial.md

-	TODO: run grpc_cli directly from our workspace's blaze?
-	TODO: web UI run directly from blaze

##### Prototype: 2 days (grpc_cli called from Bazel)

-	just use grpc_cli but run it directly from a bazel rule, like gazelle.

grpc_cli Notes

###### grpc install osx

<pre>
git submodule update --init
make
make install
# .. and for grpc:
make grpc_cli
bins/opt/grpc_cli ls localhost:9999 -l
bins/opt/grpc_cli ls localhost:9999 Say.Hello -l
bins/opt/grpc_cli type localhost:9999 Request
bins/opt/grpc_cli call localhost:9999 Say.Hello "name: 'world'"
</pre>

### Configuration

The configuration must answer a few things:

-	is the application publicly accessible?
-	does it need auth enforcement?
-	what other services does it talk to?

TBD:

-	How can the application access the config map?
-	What format is the configuration written in? jsonnet?
-	Startup configuration vs. Dynamic configuration?

We'll answer these as we move on with an example implementation.

#### Draft:

Platform config specified via Bazel rules.

Application config via jsonnet?

<pre>
go_http_server(
    name = "helloworld_server",
    binary = ":helloworld",         // go_binary

    environment_access = {          // optional

         "production": "public",    // everything else
                                    // is restricted
    },
    app_config = ":helloworld_cfg"  // optional
)

// TODO: Autogenerate this rule.
jsonnet_library(
    name = "helloworld_config",
    srcs = [
        "helloworld.jsonnet",
    ],
)
</pre>

##### Prototype: 2 days (bazel rules for go_server) - *DONE*

-	not too hard. May not even need the container stuff, do that server side (see kubefuncrunner)
-	perhaps skip the jsonnet library bits

### Pushing changes to git

User commits her changes and pushes them to a development branch. All tests on her code tree are automatically run and she can see the results in a test results UI, linked from GitHub.

She then asks for a peer review and the code is merged into the master branch. Tests are run again. If any test fails, Jessica receives a warning about post-merging test failures.

See [CI Server](CIServer.md).

### Release and Deploy

Once the new service is merged into master, a continuous deployment pipeline is automatically setup. All service environments are registered and available for service discovery.

Since Jessica decided to make this service available externally, a public URL is automatically created for the staging and development instances.

This service should only be used by the company's own clients (javascript broser clients and CLI), Jessica enabled auth enforcement for this service. The reverse proxy will only forward requests that contain valid application and user credentials in the gRPC call.

See [ReleaseMe](ReleaseMe.md).

### Operate

Monitor and Track Metrics are monitored via Prometheus and available on Grafana dashboard, including detailed stats from framework harnesses.

Once the service is in production, Jessica may opt-in to receive alerts whenever the service level objectives (SLOs) are at risk.

Logs are recorded into Elasticsearch via Logstash and can be inspected using a Kibana dashboard only accessible by Jessica's team.

Distributed traces are collected on all service environment and can be visualized in a Lightstep or Zipkin dashboard.

See [Operations](Operations.md).

Work Estimates
==============

```
$ grep "Prototype.*days" * |cut -d':' -f3
3 days (receive github hooks, run tests)
2 days (CLI to help setup a repo)
2 days (grpc_cli called from Bazel)
2 days (bazel rules for go_server) - *DONE*
7 days (prom, grafana, ELK logs)
2 days (revproxy)
3 days (build release after master push) *IN PROGRESS*
4 days (CLI to promote releases)
3 days maybe (auth for dev/staging environments)
2 days (zipkin UI + trace store)
```
