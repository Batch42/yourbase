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

\`\``$ cat elasticsearch.yaml

Versions available:
===================

https://hub.docker.com/r/centerforopenscience/elasticsearch/tags/
=================================================================

appVersion: "6.1"

image: repository: "centerforopenscience/elasticsearch" tag: "6.1" pullPolicy: "IfNotPresent"

```

```

$ helm install incubator/elasticsearch --namespace $USER --name es-release --set data.storageClass=ssd,data.storage=100Gi -f elasticsearch.yaml

```

If you do something wrong, the command to update an existing chart release is:
```

$ helm upgrade es-release incubator/elasticsearch --namespace $USER -f elasticsearch.yaml

```

## Kibana

```

$ cat kibana.yaml env:

```
    ELASTICSEARCH_URL: "http://my-release-elasticsearch-client.yves.svc.cluster.local:9200"
```

```

```

$ helm install stable/kibana --name kibana-release --namespace $USER -f kibana.yaml

```

If you do something wrong, the command to update an existing chart release is:
```

$ helm upgrade kibana-release stable/kibana --namespace $USER -f kibana.yaml

```

```

$ export POD_NAME=$(kubectl get pods --namespace yves -l "app=kibana,release=kibana-release" -o jsonpath="{.items[0].metadata.name}") $ kubectl -n $USER port-forward $POD_NAME 5601:5601 \`\`\`
