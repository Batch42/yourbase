# Moving beyond the software monolith {#monolith}

As a development team grows, the dev process is slowed down by the application monolith.

Because there are dozens of engineers adding code and dependencies to the same application, builds take several minutes or even hours. Tests are very flaky because they rely on dozens of dependencies that may or may not be working at any given time. Software releases have too many unrelated changes, so they are fragile and can take a long time to ship to users.

As a result, the company wastes money and the team becomes frustrated. People want to avoid working on that weird code base, so attrition becomes a challenge.

# **Challenges with Microservices** {#challenges}

Companies are moving to a microservices architecture to gain a competitive edge. Microservices allows faster development cycles and reduces maintenance costs by moving away from scary and hard-to-change monoliths into smaller and easier to understand microservices.

This paradigm shift is just starting but companies are finding many problems with this approach:

1. adopting microservices lead to an explosion in the number of services, which can increase maintenance cost if the management and setup of services isn't fully automated

2. legacy development workflows do not work with microservices because testing now requires bringing together a large number of independent services that interact in complex ways

3. microservices are much harder to operate in production because now there are orders of magnitude more distinct monitoring and debugging targets

4. debugging failures is much harder because of the distributed nature of request-handling in a microservices architecture.

The open source ecosystem has created incremental solutions for many of these problems, but those tools don't directly address higher-level targets such as developer productivity, service level objectives and business goals. Unsurprisingly, it's difficult for development and operations teams to create a coherent platform to run their own services.

As a result, companies have been reluctant or slow about moving to the microservices model and end up missing out on substantial business advantages they could potentially have.

# Successful transitions

The path followed by teams that successfully transitioned from monoliths was to move to smaller deployment units and use a well engineered platform that is committed to the organization's goals. Invariable, those platforms have done the following:

1. Replace the large monolith with smaller communicating applications that are released independently

2. Fully automate the setup and management of these services to avoid ops overload

3. Apply best practices to avoid introducing new problems and technical debt when developers start using the new architecture

The process can take some time to complete. But if one creates an**easy to use way to get started**, development time will quickly transition to the new stack. Developers will create new projects will be created in the better, more agile infrastructure. This process can be further accelerated with careful planning by senior engineers and architects that understand the product roadmap and know what pieces are worth carving out and moving to the new stack.

# Next Steps

* [Getting Started](getting-started.md)
* [How Does it Work](how-does-it-work.md)
* [Developing Services](developing-services.md)
