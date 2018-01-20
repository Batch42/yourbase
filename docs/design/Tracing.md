Tracing
=======

It works but the UI is awful. And it's not interesting if it's just one service writing spans. It might make sense to integrate with LightStep and friends.

### Option 1

<pre>
docker run -d -p 9411:9411 openzipkin/zipkin
# go-kit stuff:
./addsvc -zipkin-url http://localhost:9411/api/v1/spans
</pre>

### Option 2

Helm Zipkin https://github.com/Financial-Times/zipkin-helm. Depends on cassandra :-(.

Or consider mongo instead: https://github.com/nklmish/go-distributed-tracing-demo (not because it's better but because I understand it)

Cassandra on Kubernetes: https://github.com/kubernetes/charts/tree/master/incubator/cassandra

<pre>
brew install kubernetes-helm

helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
helm install --namespace "cassandra" -n "cassandra" incubator/cassandra

# See other note below.

helm status "cassandra"

# If necessary, navigate to the k8s UI to see why pods aren't scheduling. TODO: add way to tail scheduling logs
# Per the cassandra helm instructions, I need to add a persistent thingie.
curl -o create-storage-gce.yaml https://raw.githubusercontent.com/kubernetes/charts/f4d548a2b4d9042c2d72f720063ff2217c26e4fb/incubator/cassandra/sample/create-storage-gce.yaml
$ kubectl create -f create-storage-gce.yaml

Went to the k8s UI and saw nodes were out of memory. Went to the GKE UI and edited the cluster to have 5 pods rather than 3. That didn't work. Added pods with 2 cpu. That didn't work because they only give like 1.8 usable CPU.
Changed the helm chart to need fewer CPUs:
$ helm inspect values incubator/cassandra > cassandra.yaml

### $ helm upgrade --namespace "cassandra" -f cassandra.yaml cassandra incubator/cassandra

$ helm delete  --purge "cassandra" 
$ helm install -n cassandra --namespace "cassandra" -f cassandra.yaml incubator/cassandra
$ kubectl describe --namespace cassandra pods

To check the cassandra cluster status:
kubectl exec -it --namespace cassandra $(kubectl get pods --namespace cassandra -l app=cassandra-cassandra -o jsonpath='{.items[0].metadata.name}') nodetool status

helm repo add zipkin-helm https://financial-times.github.io/zipkin-helm/docs
</pre>

<pre>
$ cat create-storage-gce.yaml 
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: data-cassandra-cassandra-0
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
</pre>

### OSX success report

<pre>

helm install --namespace "cassandra" -n "cassandra" incubator/cassandra
NAME: cassandra
LAST DEPLOYED: Thu Oct 26 09:21:01 2017
NAMESPACE: cassandra
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
cassandra-cassandra ClusterIP None <none> 7000/TCP,7001/TCP,7199/TCP,9042/TCP,9160/TCP 1s

==> v1beta1/StatefulSet
NAME DESIRED CURRENT AGE
cassandra-cassandra 3 1 1s


NOTES:
Cassandra CQL can be accessed via port 9042 on the following DNS name from within your cluster:
Cassandra Thrift can be accessed via port 9160 on the following DNS name from within your cluster:

If you want to connect to the remote instance with your local Cassandra CQL cli. To forward the API port to localhost:9042 run the following:
- kubectl port-forward --namespace cassandra $(kubectl get pods --namespace cassandra -l app=cassandra-cassandra -o jsonpath='{ .items[0].metadata.name }') 9042:9042

If you want to connect to the Cassandra CQL run the following:
- kubectl port-forward --namespace cassandra $(kubectl get pods --namespace cassandra -l "app=cassandra-cassandra" -o jsonpath="{.items[0].metadata.name}") 9042:9042
echo cqlsh 127.0.0.1 9042

You can also see the cluster status by run the following:
- kubectl exec -it --namespace cassandra $(kubectl get pods --namespace cassandra -l app=cassandra-cassandra -o jsonpath='{.items[0].metadata.name}') nodetool status

To tail the logs for the Cassandra pod run the following:
- kubectl logs -f --namespace cassandra $(kubectl get pods --namespace cassandra -l app=cassandra-cassandra -o jsonpath='{ .items[0].metadata.name }')
- </pre>

Prototyping: 2 days (zipkin UI + trace store)
-------------------------------------

-	just simple Zipkin UI + cassandra on k8s, or maybe don't bother with tracing.
