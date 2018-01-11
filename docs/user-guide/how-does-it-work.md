<!-- toc -->

# Goals

**YourBase** is an open-source development platform for growing teams. The platform goals are:

* be very easy to get started
* nicely scale from small teams to large ones and perhaps help build the next Google or Facebook ;-)

YourBase is different because it's designed to scale with the size of the team and the success of the product. By leveraging YourBases's standardized frameworks and tools, you can easily setup, connect and manage multiple services with little overhead.

### Easy to get started

It only takes 5 minutes to get a production-ready Hello World service up and running in the platform. See [Getting Started](getting-started.md).

### Scalable

Well-designed microservices allow teams to scale from their first initial product all the way to very complex and high-traffic systems.

Thanks to technologies like Kubernetes, the availability of scalable cloud providers and the best practices enabled by framework harnesses, we can engineer a highly scalable system that can eventually run systems at the scale of Google or Facebook.

### Flexible

While YourBase advocates for standardization and simplification, we recognize that full uniformity isn't desirable. Teams should be able to pick and choose what part of the platform they want to use, and replace some components with others.

The platform has a very small core but most pieces are implemented as replaceable plug-ins.

### Clear transition path

We do not advocate that users migrate their monoliths to microservices. That would be costly and time-consuming. Instead, teams should create new features in the new stack. And maybe move small fast-changing pieces of the monolith into microservices. The goal should be to move the development time to the new stack - not just move the code for the sake of it.

To make this work, YourBase must interoperate well with existing systems. While it wouldn't make sense to run legacy systems using YourBase's runtime (because the legacy won't have the right harnesses), a monolith should be able to easily call a microservice and vice-versa.

# A Platform that Learns

**YourBase** follows two key metrics:

1. Software Delivery Velocity
2. Service Reliability

The platform relies upon its deep knowledge of the application and upon tracking thousands of platform signals to continuously adapt and evolve.

YourBase collects signals at each stage of the software delivery process and uses that to make changes to the pipeline, sometimes in real-time.

The delivery cycle forms a feedback loop for constantly improving _software delivery velocity_ and _service reliability_.

|  | Plan/Design | Build | Integrate | Deploy | Operate |
| :--- | :--- | :--- | :--- | :--- | :--- |
|  | → | ➡️ | ➡️ | ➡️ | ↴ |
| **Input** | Desired Product Performance | Plans and Designs | Other people's code; Test Results; | Deployable Release Unit | Deployed Service |
| **Output** | Plans and Design | Software Artifacts | Deployable Release Unit | Deployed Service | SLO observant service |
|  | ↑ | ⬅️ | ⬅️ | ⬅️ | ← |
| **Feedback** | KPIs | Technical Debt | Integration Test Failures; User Acceptance Test Failures | Regressions | Outages |

# Build

Users of **YourBase** can write services in Go, but we plan to support other languages soon.

**YourBase** will build the user's code. We will rely on user-friendly standard tools and patterns for the specification of software dependencies \(e.g: bazel\) and service APIs \(e.g: protocol buffers, swagger\).

In return, we will be able to analyze usage patterns and continuously drive improvements to the user's code and to our own frameworks and infrastructure.

## Bazel

The platform aims to support many programming languages. Developers need to be able to easily specify their software dependencies and how it should be built. Google's Bazel is an open-source tool that has several advantages:

* Same build specification for all languages
* Scales well from very small to very large large organizations
* Easy to setup and use
* High performance. Builds are very fast
* Extensible

**YourBase** uses Bazel's extensions as a hook for instantaneous analysis, testing and feedback for our user's software code. For example, it eventually could:

* automatically scan the code for security vulnerabilities
* detect concurrency issues
* show code coverage
* enforce style guides
* warn against non-hermetic test code

## API definitions

Developers should be able to create services in different languages and network transports. **YourBase** understands what service each application is providing. It inspects service definitions to deeply grasp the _purpose_ of a service. It uses this knowledge to provide features that improve the platform KPIs (delivery velocity, service reliability).

**YourBase** can understand service definition through different methods:

* Protocol Buffer files (provided by the user)
* Swagger files (provided by the user)
* (maybe) API inference (lower confidence information based upon observed traffic)

This information can be used to, for example:

* Craft synthetic requests to be used during early development and for testing
* Create service-specific and version-specific observability dashboards
* Detect and warn against backwards-incompatible changes
* Detect and warn against API definition anti-patterns

## Downstream Service Dependencies

Developers are able to connect to other services inside or outside their network. **YourBase** understands those relationships so it can address challenges and confusion related to dependency complexity.

**YourBase** obtains that information by requesting explicit service dependency declarations from developers, but it can infer other detailed information such as API specs, dependency criticality and capacity requirements.

By having an explicit declaration of service dependencies, **YourBase can**:

* Detect and prevent accidental or unintended dependencies
* Help developers browse and choose the right dependencies
* Detect and warn against relationship anti-patterns (poor retry policies, request loops and infrastructure bootstrapping cycles)
* Create dependency-specific observability dashboards
* Predict traffic demand

## Framework Harnesses

It would be great if we could fully understand an application's emergent behavior by simply inspecting its static code. That kind of technology doesn't exist today. What we can do instead is to have harnesses, or control surfaces, that _give us the ability to observe and measure the behavior of the application and to adjust it_.

Harnesses are interfaces implemented by standard programming frameworks (such as Spring Boot, go-kit, micro) or, less commonly, by custom application code. These interfaces provide privileged access to the service's state and performance which are then used by the runtime control loop to ensure the application is observing its service-level objectives.

The most common harnesses are **read-only** (e.g: logging schemes, debug endpoints, performance counters) but the platform will also rely on harnesses that can **modify** the application behavior at runtime (e.g: dynamic configuration interfaces, shutdown signals).

**YourBase** will use standardized performance counters and debug endpoints to analyze and report on the aggregated health of the service, across all instances and all clusters.

With harnesses, **YourBase** can do things out of the box that otherwise would require manual setup, such as:

* capability-specific dashboards
* _zero-confing_
  continuous deployment
* automatic canarying of releases in production
* circuit breakers
* reasonable retry behavior


## Example Harness

_BlacklistSearchApp_ uses a small custom blacklist of items that can't appear on search results.

The data safety team at SearchCo may need to make quick adjustments to this list, but doesn't want to change the data on the database directly. 

The app may store this blacklist in an external configuration. But how can the service owners **ensure the blacklist is updated safely**?

If YourBase knows that this is a search app, it automatically keeps track of key business metrics such anumber of search response items per minute. It monitors that metric whenever it deploys a new version of the blacklist. If a blacklist gets deployed that inadvertently drops all search responses, YourBases detects the change in levels after the first server instances are updated. It can pause the change rollout, call the attention to the operator and prompt them for an action.

### Fallbacks

Most application code being written today do not use frameworks with the right harnesses. The platform is flexible about that but also provides incentives for developers to increase the use of frameworks.

Ultimately, we will be able show quantitatively that applications with the right harnesse have better core metrics (delivery velocity, service reliability). We will also be able to rank and classify harnesses based on their impact towards the KPIs.

The runtime makes a clear distinction between _**required**_ and _**optional**_ harnesses. Out of the box, a traditional application or container only implements a small number harnesses, but could implement all _required_ harnesses with a few changes.

The runtime **selectively disables platform features** that depend on harnesses that are not implemented by a service release. If a change is made to the application or framework code to implement a harness, the feature is **automatically enabled for future releases**.

The platform also provides feedback to users about which features are disabled, explains why they are important and gives them clear instructions on how to satisfy the requirements.

### Frameworks Improvements

Frameworks already exist for most languages. Whenever possible we will help extend the control surfaces of the most popular frameworks via direct open source contributions or through plugins.

We will create a **harness tester tool** to check for missing/incompatible bits, which would make the problem more tractable to solve at scale.

### List of Harnesses

See [FrameworkHarnesses](/docs/design/FrameworkHarnesses.md).

# Integration

A developer's work on an application doesn't happen in isolation. They must be able to integrate work from other people. Developers use different strategies to merge changes into a consistent branch, but we can contribute to that by giving them tools to suppor the continuous integration of their work without regressions.

### CI Tests

YourBase provides a uniform way for the users to continuously test integrated code. 

YourBase leverages Bazel to easily identify what to build and reduce the need for complex CI scripts.

Git hooks trigger during pull requests and before merging code, ensuring that only changes that pass tests in a hermetic environment before they can be merged. Developers are able to view broken tests and their output.

As we learn the common causes of breakages, we can make improvements to earlier sections of the lifecycle (e.g: show warnings of non-hermetic test code) and help make developers more productive and the system more reliable.

### Service Releases

The runtime transforms bazel targets into applications binaries or container images. Internally, it wraps binaries into containers, but it can run containers directly.

Containers are merged with runtime configuration also specified through Bazel artifacts. Code+Configuration form a _release_: a hermetic deployable unit. It contains the required data and information to setup and run a service on any known environments.

## Inspection of Service Capabilities

As part of building a release, a **service inspector** analyzes the capabilities of that container image or application, and records that information, making it available for other parts of the orchestration.

For example, if the service uses a framework that provides _inbound-to-outbound scoped monitoring_ endpoints, the inspector would indicate to the **release registry** that this service+release should have that data collected and the appropriate dashboards and alerts should be enabled.

The **release registry** keeps track of read-only or slow-changing information about a **release**, which is a hermetic deployable unit containing all the required, including: who built the release and when; where can the source code be found; what are the capabilities of this release (see below).

# Operations

Releases are deployed to different environments based upon configurable policies that match with the service's risk profile. Deployments to production could be done on-demand or by schedule, but they should never require a lot of manual work.

The platform's core workflow will be fully automated, but it will also support extending deployment actions with more complex logic whenever needed.

Because YourBase understands each service's downstream dependencies, it can automatically configure services to connect to the right target for the current environment, avoiding repetitive and error-prone configuration.

## Continuous Delivery

New systems can be deployed automatically with no setup work. Creating a new service should only require a single command that connects the source code with a new entry in the _service registry_.

Git hooks will control the automatic build, test and deployment of the code into testing and staging environments. Only code that passes the appropriate Bazel tests can be promoted to the next environment.

## Service Observability

YourBase makes it easier for engineers to understand the system behavior and debug problems. It provides several features out of the box to help with troubleshooting and performance analysis.

### Logs

Capture and tag service logs and aggregate them for easy searching. The standard streaming output of processes will be collected automatically and sent to a service for logs aggregation and search. Applications can also add their own structured logging calls and all data is kept in the same place.

If all services use logging libraries that propagate context information, their logs can be merged across the stack and enable the reconstruction and visualization of individual request flows throughput the stack.

### Metrics

Key performance indicators for each service are measured from application servers directly and from proxies. Services that implement more _framework harnesses_ can leverage better out-of-the-box metrics, such as "rate of search result items" which can be used for threshold-based alerts.

The monitoring dashboards display stats about the overall system status and about the performance of both incoming and outgoing requests or queries.

### Tracing

Distributed systems are easier to understand with request tracing. Application code that has been appropriately harnessed will automatically create tracing spans for all incoming and outgoing requests. The traces are automatically pushed to a tracing storage system where they can be persisted and visualized as necessary.

## Self-healing systems

When a microservice is down, all services that depend on it also stop working. YourBase protect systems against localized outages in downstream dependencies:

- during deployment, the runtime automatically observes service-level indicators and aborts the rollout if an important regression is detected.
- services are deployed to multiple independent clusters with spare capacity so clusters can be _drained_ when problems occur. A mitigator sub-system observes the service-level indicators in all clusters and automatically moves traffic away from a cluster that isn't performing well

These self-healing features can't work for all types of outages but they can catch the most common failure events and help teams sleep better at night.

# Architecture

## Platform core

The platform has a very small core. Most pieces are implemented as replaceable plug-ins. 

For example, each stage of the delivery pipelines will provide _hook interfaces_ that allow the filtering or modification of process inputs and outputs. Users could add plugins that execute custom logic at different stages:

* before or after a new release is cut
* before or after a release is deployed to a certain environment
* before or after a change is merged in master
* before or after a certain event is logged by the application

These platform plugins run as stand-alone services or as Bazel extensions, depending on the type of event they need to work with.

## Hybrid Cluster Deployment

Deployments of the platform are isolated. We use each customer's existing or newly defined virtual private cloud (VPC). Customers provide API keys for their IaaS. We use those keys deploy new instances and manage them. We would agree to certain budget limits and/or usage expectations.

Customers can choose to deploy microservices cluster in different geographic regions and/or cloud (IaaS or Kubernetes) providers.

# UI

Use a CLI initially that talks to an API server. Make it easy to add an HTML UI later. Could potentially start implementation from here and go backwards.

See the User Journey's document with screen and interaction mock-ups.

