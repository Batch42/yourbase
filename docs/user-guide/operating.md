### Operate

Monitor and Track Metrics are monitored via Prometheus and available on Grafana dashboard, including detailed stats from framework harnesses.

![Grafana](https://i.imgur.com/F2F3xRl.png)

Once the service is in production, Jessica may opt-in to receive alerts whenever the service level objectives (SLOs) are at risk.

Logs are recorded into Elasticsearch via Logstash and can be inspected using a Kibana dashboard only accessible by Jessica's team.

Distributed traces are collected on all service environment and can be visualized in a Lightstep or Zipkin dashboard.

![LightStep](https://i.imgur.com/iR7N7Zu.png)
