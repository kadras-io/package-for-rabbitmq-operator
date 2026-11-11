# Access to the Resources

The package extends the Kubernetes [default roles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) with the RabbitMQ Cluster Operator resources, via [aggregation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles). The users bound to `admin`, `edit`, or `view` in a namespace get the following permissions on the resources in that namespace.

| Resources | `admin`, `edit` | `view` |
|-----------|-----------------|--------|
| RabbitmqCluster | Read and write | Read |

The RabbitMQ clusters of the namespace.

The permissions are granted by the `rabbitmq-operator-edit` and `rabbitmq-operator-view` ClusterRoles.
