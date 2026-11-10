# Observability

## Logs

The operator writes its logs in JSON format. The log level is one of `error`, `info`, `debug`.

```yaml
observability:
  logging:
    level: info
```

The logs can be customized further via the `zap-*` flags (see [configuration.md](configuration.md#container-flags)). For example, to write them in a human-readable format:

```yaml
args:
  zap-encoder: console
```

To read the operator logs:

```shell
kubectl logs -n rabbitmq-system deployment/rabbitmq-cluster-operator
```

The logs of the RabbitMQ nodes are written to the standard output of their Pods, and configured in each RabbitmqCluster, via `spec.rabbitmq.additionalConfig`. See [logging](https://www.rabbitmq.com/docs/logging).

## Metrics

The operator exposes metrics in the Prometheus format on port 8080 (`/metrics`), on the `metrics` container port and via the `rabbitmq-cluster-operator-metrics-service` Service. Its Pods are annotated for Prometheus scraping (`prometheus.io/scrape`, `prometheus.io/port`, `prometheus.io/path`). To remove the annotations:

```yaml
observability:
  metrics:
    enabled: false
```

If you use the Prometheus Operator, create a PodMonitor instead, or apply the [upstream one](https://github.com/rabbitmq/cluster-operator/blob/main/observability/prometheus/monitors/rabbitmq-cluster-operator-podmonitor.yml):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: rabbitmq-cluster-operator
  namespace: rabbitmq-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: rabbitmq-cluster-operator
  podMetricsEndpoints:
    - port: metrics
```

The metrics endpoint is served over HTTP. The upstream manifest includes a `metrics-certs` Certificate to serve it over HTTPS, but doesn't use it, and its DNS names are unresolved placeholders, so the package removes it. To serve the metrics over HTTPS, add a Certificate and mount its Secret with a ytt overlay, then set the `metrics-secure` and `metrics-cert-path` flags (see [configuration.md](configuration.md#container-flags)).

The RabbitMQ nodes expose their own metrics on port 15692, via the [`rabbitmq_prometheus`](https://www.rabbitmq.com/docs/prometheus) plugin, which the operator always enables. With the Prometheus Operator, apply the [upstream ServiceMonitor](https://github.com/rabbitmq/cluster-operator/blob/main/observability/prometheus/monitors/rabbitmq-servicemonitor.yml) to scrape all the RabbitMQ clusters. See [monitoring](https://www.rabbitmq.com/kubernetes/operator/operator-monitoring), and the [alerting rules](https://github.com/rabbitmq/cluster-operator/tree/main/observability/prometheus/rules) and [Grafana dashboards](https://github.com/rabbitmq/cluster-operator/tree/main/observability/grafana/dashboards) maintained upstream.

## Status

The operator reports the state of each RabbitmqCluster via its conditions (`AllReplicasReady`, `ClusterAvailable`, `NoWarnings`, `ReconcileSuccess`), and which nodes are quorum-critical via `status.quorumStatus`.

```shell
kubectl get rabbitmqcluster hello-world -o jsonpath='{.status.quorumStatus}'
```

See [quorum status](https://www.rabbitmq.com/kubernetes/operator/quorum-status) and [troubleshooting](https://www.rabbitmq.com/kubernetes/operator/troubleshooting-operator).
