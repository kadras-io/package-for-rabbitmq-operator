# High Availability

## Operator

The package runs 1 replica of the operator, which is enough for most installations: the RabbitMQ nodes keep running and serving traffic while the operator is unavailable, and the operator reconciles them again when it's back. However, the admission webhooks served by the operator reject the changes to the RabbitmqClusters while no replica is available.

The operator runs with leader election: additional replicas are standby, and all of them serve the admission webhooks. With more than one replica, a PodDisruptionBudget keeps at least one available during node drains.

```yaml
replicas: 2
```

The leader election timings can be tuned via the `LEASE_DURATION`, `RENEW_DEADLINE`, and `RETRY_PERIOD` variables, in seconds (see [configuration.md](configuration.md#operator-environment-variables)). To keep the operator off the nodes running the RabbitMQ clusters, see [configuration.md](configuration.md#node-placement).

## RabbitMQ clusters

The high availability of the RabbitMQ clusters is configured in each RabbitmqCluster, with the number of replicas, their affinity, and the replication of the queues and streams. Use an odd number of replicas, and [quorum queues](https://www.rabbitmq.com/docs/quorum-queues) or [streams](https://www.rabbitmq.com/docs/streams) for the data that must survive the loss of a node.

The operator doesn't create a PodDisruptionBudget for the RabbitMQ clusters. Create one for each cluster, selecting its Pods via the `app.kubernetes.io/name` label, set to the name of the RabbitmqCluster:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: hello-world
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: hello-world
```

When a RabbitMQ node is stopped, its `preStop` hook waits until no quorum queue or stream would lose its majority, for up to `spec.terminationGracePeriodSeconds` (one week by default). The `status.quorumStatus` of a RabbitmqCluster shows which nodes are quorum-critical. See [quorum status](https://www.rabbitmq.com/kubernetes/operator/quorum-status).

## Operator upgrades

Some operator upgrades roll out the RabbitMQ clusters. See [upgrade.md](upgrade.md) to defer the rollout of a cluster.
