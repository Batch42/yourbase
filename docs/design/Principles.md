# Platform Principles

We offer software tools that help teams transition to a more agile infrastructure. Here's what we aim to provide.

## **Make application servers that are released independently with less dev friction**

Enable polyglot development using the team's approved languages, with support for popular languages and frameworks.

Allow local development using familiar tools and IDEs.

Have the ability to build and test servers locally with tools that are easy to install and use.

Be able to automatically pull, build and run dependencies for local testing. When necessary, support the usage of _fakes_ that simplify the testing environment.

Create new *release artifacts and pipelines* with zero setup work based on simple service metadata.

## **Transition path must be clear**

Allow a smooth and gentle transition into a modern application infrastructure. It doesn't matter how good the new infrastructure if there is no reasonable transition path.

Teams should be able to use both platforms at the same time during a transition, but accelerate development on the new platform.

New code and old code should be able to communicate through the SoA network.

Ideally we should offer tools to help people  move to the new infrastructure.

## **Help developers follow programming best practices**

Developers that didn't write distributed software before may be faced with a significant learning curve when writing distributed systems, and could make many expensive mistakes along the way.

The platform must offer tools that can be used by teams to apply best practices to their code and reduce the chances and the impact of common mistakes, including:

* Test code that depends on flaky services, making the test flaky

* Initialization code that doesn't check if dependencies are ready, leading to errors during startup and shutdown

* Dependency setup code that blocks the server startup for too long, slowing down software updates

* Retry logic that just retries on the same endpoint and is _ineffective_ or that is _too effective_ and causes system overload

The platform must provide code analysis and runtime checks that verify and warn against common anti-patterns.

## **Applications communicate seamlessly with their dependencies**

Services must communicate with other services in the network via load balancing and service discovery. All communication between services must be secured and tracked.

Services should easily connect to the appropriate dependencies for each environment, avoiding repetitive configuration.

## **Easy to get started**

If the team decides that a new service should exist, it should be trivial for them to create one. The system topology and architecture should be decided based on business requirements and domain knowledge, and not artificially constrained by platform limitations.

## **Fully automated orchestration and management of services**

Services running in the microservices platform should auto-heal, auto-scale and be deployable following best-practices such as canarying of new releases, without the need for human involvement.

The operation of most services should be fully automated. Service owners could also opt-out from automatic production deployments for services with a different risk profile.

## **Self-healing systems**

The platform must be resilient to new failure modes not present in the software monolith.

Services run independently and are updated independently. That means they each have separate failure events. Not only your system may be unavailable, but a downstream dependency may be unavailable, slow or overloaded. These event are so common in practice that we must design the platform to deal with them and self-heal as fast as possible, without waiting for operator involvement

Software updates may introduce bugs causing servers to crash or fail to start. The platform must be able monitor and identify these conditions, avoid sending traffic to broken endpoints, and try to automatically recover them to a previously known configuration.

