Load Balancing, Service Discovery
=================================

Services must communicate with other services in the network via load balancing and service discovery. All communication between services must be secured and tracked.

Service Discovery
-----------------

We'll use whatever the kubernetes community has been using the most. Currently etcd is used throughout kubernetes. Service discovery is often done via DNS based on etcd address. That is enough for most simple use cases.

Over time we may need to allow clients to make advanced service discovery queries - letting them use the kubernetes API is one way to solve it.

Load Balancing
--------------

We'll start simple. Initially, we'll use external-to-internal load balancer from cloud providers since they require less configuration.

Over time, we also have to:

-	support load balancing that is agnostic to specific cloud providers.
-	support load balancing for internal traffic.

Internal traffic can initially be routed through the cloud load balancers. That's not super efficient so over time we'll deploy internal solutions, too.

There are many projects related to this discussion, including haproxy, istio/envoy, etc. We'll expand this document as we learn about other requirements and think of better ideas.

NGinx is also a great choice. Here's a working configuration, courtesy of a user in the k8s slack: https://gist.github.com/mikejk8s/d7d7e71652fd838359968b221f756852
