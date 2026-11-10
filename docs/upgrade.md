# Upgrading

Read the [release notes](https://github.com/rabbitmq/cluster-operator/releases) of each RabbitMQ Cluster Operator version before upgrading, since some versions require extra steps.

```shell
kctrl package installed update -i rabbitmq-operator -v ${VERSION} -n kadras-system
```

Upgrading the operator updates the RabbitmqCluster CRD and the operator. It doesn't change the specification of the existing RabbitmqClusters: the RabbitMQ version stays the same, and only the new RabbitmqClusters that don't set `spec.image` get the default image of the new operator version. To upgrade RabbitMQ, update `spec.image` in each RabbitmqCluster, following the [RabbitMQ upgrade guide](https://www.rabbitmq.com/docs/upgrade).

However, an operator upgrade that changes the Pods it generates rolls out all the RabbitMQ clusters, one node at a time, which the release notes mention. See [upgrading the operator](https://www.rabbitmq.com/kubernetes/operator/upgrade-operator).

## Defer the rollout

To defer the rollout of a RabbitMQ cluster, pause its reconciliation before upgrading the operator. While paused, the operator ignores the changes to the RabbitmqCluster, and doesn't recreate the resources deleted from it.

```shell
kubectl label rabbitmqcluster hello-world rabbitmq.com/pauseReconciliation=true
```

Resume it when convenient. The operator then applies the pending changes, rolling out the cluster:

```shell
kubectl label rabbitmqcluster hello-world rabbitmq.com/pauseReconciliation-
```

## Automatic RabbitMQ upgrades

With the experimental `CONTROL_RABBITMQ_IMAGE` variable, the operator sets the RabbitMQ image of all the RabbitmqClusters to its default, so that upgrading the operator also upgrades RabbitMQ, without any safety or compatibility check (see [configuration.md](configuration.md#operator-environment-variables)).

```yaml
env:
  CONTROL_RABBITMQ_IMAGE: true
```

## Uninstalling

The PersistentVolumeClaims of the RabbitMQ nodes are deleted with their RabbitmqCluster: deleting a RabbitmqCluster deletes all its data. Deleting the RabbitmqCluster CRD would delete all the RabbitmqClusters. Uninstalling the package doesn't delete them: it keeps the CRD and the operator namespace, and only deletes the operator and its webhooks. The RabbitMQ nodes keep running without the operator. Installing the package again resumes the reconciliation.

To remove everything, delete the RabbitmqClusters before uninstalling the package, while the operator still runs, then delete the CRD and the namespace.

```shell
kubectl delete rabbitmqclusters.rabbitmq.com --all -A
kctrl package installed delete -i rabbitmq-operator -n kadras-system
kubectl delete crd rabbitmqclusters.rabbitmq.com
kubectl delete namespace rabbitmq-system
```
