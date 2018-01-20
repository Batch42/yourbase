Kubernetes Control
==================

How are we going to work programmatically with kubernetes?

I had some good experience calling kubernetes directly from its Go clients, but I also recognize that's not the standard choice for operators out there.

If we become highly productive about controlling k8s from Go, and create a nice architecture around it, that would lead to an "automated infrastructure" rather than an "infrastructure with a bunch of scripts".

I personally really don't want to work with a code base consisting of disconnected scripts. The only way to make this work is to have an intuitive control architecture, and the best way to implement an elegant and high performance architecture is through event or request-driven functions - without having to execute shell commands - that are typically higher-latency and harder to debug and test.

We clearly won't produce an intuitive architecture during Phase 1. But the hackish code snippets we create now could be used later on for the later versions. And if we invest on a little bit of testing now, we can evolve the architecture really nicely, too.

Decision:

-	Use Go kubernetes client code
-	Have functional testing in place so it's easier to evolve the messy Phase 1 code base.

References
==========

-	https://github.com/kubernetes/client-go/tree/master/examples
