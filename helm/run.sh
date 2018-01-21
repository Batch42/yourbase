#!/bin/bash

set -eu

# Setup a storage class on GCP. OK if the already exists.
kubectl create -f - <<EOF 2>&1 |grep -v exists || true
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
EOF

# Install elasticsearch
helm upgrade es-release incubator/elasticsearch --install --namespace logging -f elasticsearch.yaml

# Install kibana
helm upgrade kibana-release stable/kibana --install --namespace logging -f kibana.yaml

# Install fluent-bit to send all container logs to ELK
# NOTE: This may require a force delete and a recreation other it doesn't seem
# to act on config changes.
helm upgrade fluent-bit-release stable/fluent-bit --install --namespace logging -f fluent-bit.yaml

echo 'Now try doing a Kibana port-forward so you can access the dashboard at http://localhost:5601/'
echo
echo 'export POD_NAME=$(kubectl get pods --namespace logging -l "app=kibana,release=kibana-release" -o jsonpath="{.items[0].metadata.name}")'
echo
echo 'kubectl -n logging port-forward $POD_NAME 5601:5601'
