Logging Infra
=============

We'll use an ELK cluster to aggregate logs, and fluent-bit to collect all logs from the nodes.

This provides:
- nice UI for users (Kibana)
- searches (e.g: CI build log for a certain commit)
- aggregation (e.g: total number of CI builds by a user)

Magically, it also aggregates *all* our kubernetes logs, for the entire infrastructure.

If YourBase apps that use the right kind of log format, they'll get all of the nice stuff for free (in fact, we can help enforce that).

ElasticSearch, Kibana and fluent-bit will all be deployed via Helm charts.

# Installation

For now, the charts are not part of our Bazel graph, so users have to download and use helm as a separate thing. That's not cool. I really don't want to add new things. I'd rather ask users to do "bazel run :cluster" and everything gets deployed/updated for them.

Currently we have just a shell script that installs everything. It's idempotent so it can be run multiple times to update things. 

I have some ideas for how to make this nice and proper inside Bazel, see [Helm](Helm.md) and [BazelOrNot](BazelOrNot.md).

## Kibana Port Forward

```bash
export POD_NAME=$(kubectl get pods --namespace logging -l "app=kibana,release=kibana-release" -o jsonpath="{.items[0].metadata.name}")

kubectl -n logging port-forward $POD_NAME 5601:5601
```

Test it out
=====

Generate some logs:

```
kubectl create -n default -f https://k8s.io/docs/tasks/debug-application-cluster/counter-pod.yaml
pod "counter" created
```

Or alternatively run a CI live_test.sh (assuming the CI server is running on your namespace):

```
ci/tools/live_test.sh
```

Go to the kibana dashboard, which should be accessible after the second port-forward above: http://localhost:5601.
