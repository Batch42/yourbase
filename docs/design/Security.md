Security
========

Our Phase 1 won't be very secure. We'll use a shared kubernetes and there won't be a lot of isolation between deployments. One can conceivably wipe the entire cluster state with a malicious pod.

Future versions will need to ensure:

-	Isolation between deployments, largely accomplished by having separate k8s clusters. For the shared cluster, we'll look more closely into k8s isolation mechanisms - perhaps namespaces or so.
-	Isolation for roles within a customer network. Most users should not have k8s credentials.
