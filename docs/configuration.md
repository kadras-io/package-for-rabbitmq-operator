# Configuration

The package values cover the decisions most installations need to make: the operator namespace and replicas, the namespaces it watches, the defaults for new RabbitMQ clusters, and observability. Everything else can still be customized in three ways.

## Operator environment variables

The operator reads its configuration from environment variables, at startup. The package computes some variables from the values, then merges `env` on top, so its variables take precedence. A variable set to `null` is removed. A change rolls out the operator.

```yaml
env:
  DEFAULT_USER_UPDATER_IMAGE: registry.example.com/rabbitmq/default-user-credential-updater:1.0.14
  LEASE_DURATION: 30
  RENEW_DEADLINE: 20
  RETRY_PERIOD: 4
```

The available variables are listed in [configuring defaults](https://www.rabbitmq.com/kubernetes/operator/configure-operator-defaults). The ones computed by the package are:

| Variable | Value |
|----------|-------|
| `OPERATOR_SCOPE_NAMESPACE` | `watch_namespaces`, comma-separated |
| `DEFAULT_RABBITMQ_IMAGE` | `defaults.image` |
| `DEFAULT_IMAGE_PULL_SECRETS` | `defaults.image_pull_secrets`, comma-separated |

The upstream `OPERATOR_NAMESPACE` variable, read from the Pod metadata, is always kept.

### Watched namespaces

By default, the operator watches the RabbitmqClusters in all namespaces. To limit it to some namespaces:

```yaml
watch_namespaces:
  - messaging
  - team-a
```

The operator still runs with its ClusterRole, and the admission webhooks still validate the RabbitmqClusters in all namespaces. The ones outside the watched namespaces are just not reconciled.

### Cluster defaults

The operator applies some defaults to the RabbitmqClusters that don't set them, when they are created: the RabbitMQ image, and the Secrets to pull it. Changing the defaults doesn't affect the existing RabbitmqClusters.

```yaml
defaults:
  image: registry.example.com/rabbitmq:4.3.4-management
  image_pull_secrets:
    - registry-credentials
```

By default, the RabbitMQ image is the one of the operator release (`rabbitmq:4.3.4-management` for the operator 2.23.2), without pull secrets. The pull secrets are referenced by name in the namespace of each RabbitmqCluster, so they must exist there. See [security.md](security.md#private-registries).

## Container flags

The operator is configured via container flags too. The package computes the log level from the values and merges it into the upstream flags, then merges `args` on top, so its flags take precedence. The flags are written without the leading dashes, and a flag set to `null` is removed.

```yaml
args:
  zap-encoder: console
  zap-stacktrace-level: panic
```

Besides the [logging flags](https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/log/zap#Options.BindFlags) (`zap-*`), the operator accepts `metrics-bind-address`, `metrics-secure`, `metrics-cert-path`, `health-probe-bind-address` and `enable-http2`. An unknown flag prevents the operator from starting. A change rolls out the operator.

## ytt overlays

Any Kubernetes resource of the package can be customized with a [ytt overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/). Store it in a Secret and reference it from the PackageInstall via the `ext.packaging.carvel.dev/ytt-paths-from-secret-name.0` annotation.

```shell
kubectl create secret generic rabbitmq-operator-overlays -n kadras-system --from-file=overlays.yml
kubectl annotate packageinstall rabbitmq-operator -n kadras-system \
  ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=rabbitmq-operator-overlays
```

The operator runs in the `rabbitmq-cluster-operator` Deployment, in a container named `operator`.

### Resources

The upstream manifest requests and limits 200m CPU and 500Mi memory, which can be too little when managing many RabbitMQ clusters.

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "rabbitmq-cluster-operator"}})
---
spec:
  template:
    spec:
      containers:
        #@overlay/match by="name"
        - name: operator
          resources:
            limits:
              cpu: 500m
              memory: 1Gi
            requests:
              cpu: 500m
              memory: 1Gi
```

### Node placement

Keep the operator off the nodes running the RabbitMQ clusters, so that a node failure doesn't take down both.

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "rabbitmq-cluster-operator"}})
---
spec:
  template:
    spec:
      #@overlay/match missing_ok=True
      nodeSelector:
        node-restriction.kubernetes.io/reserved-for: platform
      #@overlay/match missing_ok=True
      tolerations:
        - key: node-restriction.kubernetes.io/reserved-for
          operator: Equal
          value: platform
          effect: NoExecute
```
