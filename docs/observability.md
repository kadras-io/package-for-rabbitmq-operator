# Configuring Observability

Monitor and observe the operation of the RabbitMQ Operator using logs and metrics.

## Logs

Log configuration for the RabbitMQ Operator can be customized as follows.

```yaml
logging:
  level: info
```

## Metrics

Metrics configuration for the RabbitMQ Operator deployment is enabled by default using the Prometheus format. This package comes pre-configured with the necessary annotations to let Prometheus scrape metrics automatically from all its components.

If you'd like to remove the Prometheus annotations and therefore disable automatic scraping of RabbitMQ Operator metrics, you can apply the following configuration:

```yaml
prometheus:
  enabled: false
```

For more information, check the RabbitMQ Operator documentation for [metrics](https://www.rabbitmq.com/kubernetes/operator/operator-monitoring).
