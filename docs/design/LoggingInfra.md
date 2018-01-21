Logging Infra
=============

ELK deployed via Helm charts.

TODO: Move everything into a Bazel rule?

StorageClass on GCP
-------------------

```
$ kubectl create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
EOF
```

Install elasticsearch
---------------------


```
$ helm install incubator/elasticsearch --namespace logging --name es-release -f elasticsearch.yaml
```

If you do something wrong, the command to update an existing chart release is:

```
$ helm upgrade es-release incubator/elasticsearch --namespace logging -f elasticsearch.yaml
```

## Kibana

```
$ helm install stable/kibana --name kibana-release --namespace logging -f kibana.yaml
```

If you do something wrong, the command to update an existing chart release is:

```
$ helm upgrade kibana-release stable/kibana --namespace logging -f kibana.yaml
```

```
$ export POD_NAME=$(kubectl get pods --namespace logging -l "app=kibana,release=kibana-release" -o jsonpath="{.items[0].metadata.name}")
$ kubectl -n logging port-forward $POD_NAME 5601:5601
```

Fluent-bit
=======

This awesome thing sends all your logs to ES. 

TODO: should it be deployed in the logging namespace, too? Does it make any difference?

``` 
helm install --name fluent-bit-release stable/fluent-bit --namespace logging -f fluent-bit.yaml
```
NOTE: changes to the config don't seem to reflect live after `helm upgrade`, not even with `--recreate-pods` or `--force`.

Test it out
=====

Generate some logs

```
$ kubectl create -n default -f https://k8s.io/docs/tasks/debug-application-cluster/counter-pod.yaml
pod "counter" created
```

Go to the kibana dashboard, which should be accessible after the second port-forward above: http://localhost:5601.