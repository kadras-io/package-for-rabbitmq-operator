# Security

## Pod Security Standards

The operator complies with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on the package namespace. With their default security contexts, the RabbitMQ Pods comply with it too, so it can be enforced on the namespaces of the RabbitmqClusters. A RabbitmqCluster can override them via `spec.override.statefulSet`, so Pod Security Admission, not the operator, is the boundary.

## Permissions

The operator runs with the `rabbitmq-cluster-operator` ServiceAccount, bound to the `rabbitmq-cluster-operator-role` ClusterRole, since it manages the RabbitMQ clusters in all namespaces. It also executes commands in the RabbitMQ Pods, like `rabbitmq-queues rebalance all` after an update. Limiting the watched namespaces via `watch_namespaces` doesn't reduce its permissions.

Anyone who can create or update a RabbitmqCluster can set any field of its Pods, via `spec.override`, so grant write access to the RabbitmqClusters only to trusted users.

The package includes the upstream `rabbitmq-cluster-service-binding-role` ClusterRole, which grants read access to the RabbitmqClusters, for [Service Binding](https://servicebinding.io) implementations.

## Credentials

The operator generates the credentials of the default user of each RabbitmqCluster, in the `<cluster>-default-user` Secret, and the Erlang cookie, in the `<cluster>-erlang-cookie` Secret. If one of them is deleted, the operator creates it again with new values, which aren't applied to the running RabbitMQ nodes. To store the credentials in [Vault](https://www.vaultproject.io) instead, see `spec.secretBackend.vault` in [using the operator](https://www.rabbitmq.com/kubernetes/operator/using-operator).

## Private registries

The `canonical-registry-credentials` Secret in the package namespace holds the credentials to pull the operator image from a private registry. It's populated by [secretgen-controller](https://github.com/carvel-dev/secretgen-controller) from a Secret exported to the package namespace.

The RabbitMQ images aren't part of the package, and the RabbitMQ Pods don't use that Secret. In air-gapped environments, relocate them separately and reference them from the RabbitmqClusters, via `spec.image` and `spec.imagePullSecrets`, or set the defaults for new clusters (see [configuration.md](configuration.md#cluster-defaults)):

```yaml
defaults:
  image: registry.example.com/rabbitmq:4.3.4-management
  image_pull_secrets:
    - registry-credentials
env:
  DEFAULT_USER_UPDATER_IMAGE: registry.example.com/rabbitmq/default-user-credential-updater:1.0.14
```

The pull secrets must exist in the namespace of each RabbitmqCluster. With secretgen-controller, create a placeholder Secret there:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-credentials
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K
```

The `DEFAULT_USER_UPDATER_IMAGE` is only used by the RabbitmqClusters that store their credentials in Vault.

## Admission webhooks

The operator serves the admission webhooks that default and validate the RabbitmqClusters, on port 9443. Their certificate is issued by cert-manager, via the `cluster-operator-serving-cert` Certificate and the `selfsigned-issuer` Issuer, stored in the `cluster-operator-webhook-server-cert` Secret, and cert-manager injects its CA into the webhook configurations. The package keeps the injected CA when it's reconciled.

On some managed Kubernetes services, like private GKE clusters, a firewall blocks the traffic from the control plane to the nodes, except for a few ports. If creating a RabbitmqCluster fails with `failed calling webhook`, open port 9443 in the firewall.

## TLS

The RabbitMQ clusters serve the client connections over TLS with the certificate in the Secret referenced by `spec.tls.secretName`, for example issued by cert-manager. The traffic between the RabbitMQ nodes can be encrypted too, via `spec.tls.interNode`, which requires the [cert-manager CSI driver](https://cert-manager.io/docs/usage/csi-driver/) and a CA Issuer. See [TLS](https://www.rabbitmq.com/kubernetes/operator/using-operator#tls).

## Network policies

The package doesn't include network policies. If you add some, allow:

* the inbound traffic from the Kubernetes API server to the operator on port 9443 (admission webhooks), and from Prometheus on port 8080 (metrics);
* the outbound traffic from the operator to the Kubernetes API server, and to the RabbitMQ nodes on port 15672, or 15671 with TLS (management API, used for the quorum status and the deprecated features checks).

See the [network policies example](https://github.com/rabbitmq/cluster-operator/tree/main/docs/examples/network-policies) for the RabbitMQ clusters.

## Image verification

The package is signed. See [verify-release.md](verify-release.md).
