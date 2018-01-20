Operations
==========

Monitor and Track Metrics are monitored via Prometheus and available on Grafana dashboard, including detailed stats from framework harnesses.

Once the service is in production, Jessica may opt-in to receive alerts whenever the service level objectives (SLOs) are at risk.

Logs are recorded into Elasticsearch via Logstash and can be inspected using a Kibana dashboard only accessible by Jessica's team.

Distributed traces are collected on all service environment and can be visualized in a Lightstep or Zipkin dashboard.

Prometheus
==========

-	Monitors all registered services and all environments with no extra setup from users
-	Scales to as many tasks as needed for that customer [v2+]
-	Consider making load tests very easy to run to "warm up" the graphs and make the first user experience more interesting (see below).

Grafana
=======

-	Landing page that lists or allows searching all services and respective environments
-	Easy to switch between environments for a service
-	Jump to dependencies [v2+]
-	Show monitoring panes based upon release capability (see "service inspector" at [Design](Design.md)) [v2+]
-	Basic container stats
-	Language-specific stats
-	Framework-specific stats
-	Request stats
-	Client request stats
-	Request-scoped client request monitoring [v2+]

Logs
====

ELK stack for the win? Can we use logz.io for this? I've had only positive experiences with them so far but my use case was simple. Seamless integration would be awesome, but how would our users authenticate with them?

Tracing
=======

See [Tracing](Tracing.md).

OpenZipkin works but the UI is awful. And it's not interesting if it's just one service writing spans. I talked to LightStep and they said they would get back to me about an integration. They aren't quite there yet.

Alerts
======

-	Job is fully unavailable
-	&gt; 3% errors on reverse proxy errors
-	send them from Prometheus to..hmm.. PagerDuty? Can we integrate with them?
-	Allow users to specify simple SLOs [v2+]

Load Testing
============

Load testing is useful in practice but it could also be a good way to warm up people's graphs and make the initial experience more interesting.

We may use something like gofuzz for this. https://github.com/google/gofuzz

Or this https://github.com/dave/blast. Currently doesn't support gRPC. Sent @dave an email about it.

Prototype: 7 days (prom, grafana, ELK logs)
-------------------------------------

-	Prometheus that collects everything and stores in whatever
-	Grafana graphs that make sense for the helloworld
-	Logs to shared ELK stack. No security.
-	Tracing: separate doc, see [Tracing](Tracing.md)
-	No alerts
-	Single cluster

References
==========

-	[how a simple [kubernetes] web app that monitors for config file changes looks like](http://thrawn01.org/posts/2016/03/22/howto-write-configmap-enabled-golang-microservices/)
