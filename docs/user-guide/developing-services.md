YourBase
=============

YourBase is a platform for the development of services that scales with a growing team. In this guide we'll show you how to quickly develop maintainable gRPC servers in Go or nodeJS.

**This document isn't quite finished. Consider looking at [How Does It Work](how-does-it-work.md) and [Getting Started](getting-started.md) instead.**

Getting Started
===============

Objective: build a simple server, test it with a nice UI. Then deploy and productionize it.

## userevents.proto



```protobuf
syntax = "proto3";

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
```

## gRPC server code

{% method %}

{% sample lang="go" %}

```go
package main

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
```

{% sample lang="js" %}

Highlights:
* the same nodeJS + npm workflow you're used to
* no need to fight the deployment setup
* the BUILD file replaces Dockerfile, Vagrant and Jenkins. Used to drive the entire service automation.

```js
'use strict';

const fs = require('fs');
const grpc = require('grpc');
const serviceDef = grpc.load("message.proto");
const PORT = 7777;

const cacert = fs.readFileSync('certs/ca.crt'),
      cert = fs.readFileSync('certs/server.crt'),
      key = fs.readFileSync('certs/server.key'),
      kvpair = {
          'private_key': key,
          'cert_chain': cert
      };
const creds = grpc.ServerCredentials.createSsl(cacert, [kvpair]);

var tstcoordinates = [
    {
        id: 1,
        firstname: "Bill",
        lastname: "Williams",
        email: "williams@example.com",
        areacode: "444",
        phone: "555-1212",
        extension: "378"
    },
    {
        id: 2,
        firstname: "Happy",
        lastname: "Golucky",
        email: "lucky@example.com",
        areacode: "444",
        phone: "555-1212",
        extension: "382"
    }
];

var server = new grpc.Server();

server.addService(serviceDef.TstService.service, {
    list: function(call, callback) {
        console.log("in list");
        callback(null, tstcoordinates[0]);
    },
    sendCoordinates: function(call, callback) {
        console.log("in sendCoordinates");
        callback(null, tstcoordinates[1] );
        return;
    }
});

server.bind(`0.0.0.0:${PORT}`, creds);
console.log(`Starting gRPC server on port ${PORT}`);
server.start();

# Source: https://stackoverflow.com/questions/44249257/no-response-from-nodejs-grpc-server
```
{% common %}
## Build and Test

YourBase comes with many simple built-in tests for all types of servers we support It's also very easy to add new service-specific tests, as you'll see.

### Generate BUILD.bazel files

Bazel is very extensible and we use that to do a lot of the hard work involving software testing and delivery. Before we can do that we have to tell Bazel how to build our programs.

{% sample lang="go" %}

In Go, we just have to run `gazelle` and it will automatically generate BUILD.bazel files based upon the current directory contents.

```
$ bazel run //:gazelle
```

{% sample lang="js" %}

```python
load("@build_bazel_rules_nodejs//:defs.bzl", "nodejs_binary")

nodejs_binary(
    name = "example",
    data = [
        "@//:node_modules",
        "main.js",
    ],
    entry_point = "workspace_name/main.js",
    args = ["--node_options=--expose-gc"],
)
```

{% common %}



{% common %}

### Testing

See [Testing Services](testing-services.md).


### Configuration

The configuration must answer a few things:

-	is the application publicly accessible?
-	does it need auth enforcement?
-	what other services does it talk to?

#### Startup configuration

Servers need configuration for many reasons:

- select addresses to connecting to dependencies
- protect new behavior or features behind a flag and roll it independently of binary releases
- ability to quickly change the application behavior for routine procedural changes (e.g: edit a list of blocked user IDs) without waiting for application rollouts

We use `jsonnet` for our application config. It's great if you're already familiar with JSON.

## helloworld.jsonnet

```python
// TODO: Autogenerate this rule.
jsonnet_library(
    name = "helloworld_config",
    srcs = [
        "helloworld.jsonnet",
    ],
)
```

## BUILD.bazel

{% sample lang="go" %}

The `go_server` entry is the last piece of the puzzle. It's will be cut into a release artifact and will be deployed to various stages, from development, to staging and to production.

```python
go_server(
    name = "helloworld_server",
    binary = ":helloworld",         # go_binary defined above

    environment_access = {          # optional
         "production": "public",    # everything else is restricted
    },
    app_config = ":helloworld_cfg"  # optional
)

```

{% sample lang="js" %}

The `nodejs_server` entry is the last piece of the puzzle. It's will be cut into a release artifact and will be deployed to various stages, from development, to staging and to production.


```python
nodejs_server(
    name = "helloworld_server",
    binary = ":helloworld",         # nodejs_binary defined above
    environment_access = {          # optional
         "production": "public",    # everything else is restricted
    },
    app_config = ":helloworld_cfg"  # optional
)
```

{% common %}

{% endmethod %}

# Recap
`TODO revisit benefits`

# Next steps

* [Deploying](Deploying.md)
* [Connecting to other services](connecting.md)
* [Operating](operating.md)
