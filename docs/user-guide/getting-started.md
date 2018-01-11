# Getting Started with YourBase

YourBase is a service development platform that scales with a growing team. 

It's easy to get started.

## Installation

Install the YourBase bazel bundle [(why bazel?)](README.md#Bazel) to get started.

```
$ curl https://bundle.yourbase.io | bash
  Downloading Bazel... done
  Downloading initial build cache... done
  Installing the `mci` CLI... done
  Creating credentials... done
```

## Repository setup

YourBase needs to setup a few things on your git repository:

1. add a WORKSPACE and a BUILD.bazel file to the root of your repository
1. add 'bazel-*' to your .gitignore file
1. configure a hook on your git hosting to find out when new code is pushed

You can use an existing repository or setup a new one. In either case, the procedure is the same:

```
$ mci setup-repo https://github.com/me/myproject
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
```

You can test your setup by doing a commit and observing the repository view on YourBase's CI dashboard at  https://yourbase.io/ci/.

```
$ echo >> WORKSPACE
$ git commit -m"Testing change" WORKSPACE
$ git push origin master
```

TODO: screenshot of repo build status. It's not going to have anything interesting but it should show that it's working.

## Hello World!

YourBase comes with example gRPC and HTTP services that you can build and inspect. You can fetch and build them in a single step by running:

```
$ bazel build @yourbase//examples/helloworld/go:grpc_server
...

$ bazel build @yourbase//examples/helloworld/go:grpc_client
```

Since building also fetches the source code, the code is now available in the `bazel-external` directory. The `bazel-*`directories are **not** part of your repository - they are ignored by git.

Here's the Go server code:

```
$ cat bazel-external/yourbase/examples/helloworld/
package main

import (
	"flag"
	"fmt"
	"log"
	"net"

	pb "github.com/bazelbuild/rules_k8s/examples/hellogrpc/proto/go"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
)

var port = flag.String("port", "50051", "port to listen")

func main() {
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%s", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterSimpleServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}

type server struct{}

func (s *server) Foo(ctx context.Context, req *pb.FooRequest) (*pb.FooReply, error) {
	return &pb.FooReply{
		Message: fmt.Sprintf("DEMO %s", req.Name),
	}, nil
}
```

Run the server:

```
$ bazel-bin/yourbase/examples/helloworld/go:grpc_server
Starting gRPC server on port 8888
```

Run the client from a different terminal:
```
$ bazel-bin/yourbase/examples/helloworld/go:grpc_client
Sending "Hello"
Received "World"
```

If all this works, it means your work environment is fully setup and you should be able to deploy your services to production with a few more commands. The other sections explore how do you create your own service and how can you launch and modify services.

## Next steps

* [Developing a Service](developing-services.md)
* [Deploying a Service](deploying.md)
* [How Does it Work](how-does-it-work.md)
