# RabbitMQ Operator

![Test Workflow](https://github.com/kadras-io/package-for-rabbitmq-operator/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/package-for-rabbitmq-operator/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Bluesky](https://img.shields.io/static/v1?label=Bluesky&message=Follow&color=1DA1F2)](https://bsky.app/profile/kadras.bsky.social)

A Carvel package for [RabbitMQ Operator](https://www.rabbitmq-operator.com/docs/kubernetes/operator/operator-overview), an open-source message broker supporting multiple messaging protocols and streaming.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.33+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

  ```shell
  kapp deploy -a kapp-controller -y \
    -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
  ```

### Installation

Add the Kadras [package repository](https://github.com/kadras-io/kadras-packages) to your Kubernetes cluster:

  ```shell
  kctrl package repository add -r kadras-packages \
    --url ghcr.io/kadras-io/kadras-packages \
    -n kadras-system --create-namespace
  ```

<details><summary>Installation without package repository</summary>
The recommended way of installing the RabbitMQ Operator package is via the Kadras <a href="https://github.com/kadras-io/kadras-packages">package repository</a>. If you prefer not using the repository, you can add the package definition directly using <a href="https://carvel.dev/kapp/docs/latest/install"><code>kapp</code></a> or <code>kubectl</code>.

  ```shell
  kubectl create namespace kadras-system
  kapp deploy -a rabbitmq-operator-package -n kadras-system -y \
    -f https://github.com/kadras-io/package-for-rabbitmq-operator/releases/latest/download/metadata.yml \
    -f https://github.com/kadras-io/package-for-rabbitmq-operator/releases/latest/download/package.yml
  ```
</details>

Install the RabbitMQ Operator package:

  ```shell
  kctrl package install -i rabbitmq-operator \
    -p rabbitmq-operator.packages.kadras.io \
    -v ${VERSION} \
    -n kadras-system
  ```

> **Note**
> You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.
> 
>   ```shell
>   kctrl package available list -p rabbitmq-operator.packages.kadras.io -n kadras-system
>   ```

Verify the installed packages and their status:

  ```shell
  kctrl package installed list -n kadras-system
  ```

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.
For documentation specific to RabbitMQ Operator, check out [rabbitmq-operator.com](https://www.rabbitmq-operator.com/docs/kubernetes/operator/operator-overview).

## 🎯&nbsp; Configuration

The RabbitMQ Operator package can be customized via a `values.yml` file.

  ```yaml
  logging:
    level: info
  ```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

  ```shell
  kctrl package install -i rabbitmq-operator \
    -p rabbitmq-operator.packages.kadras.io \
    -v ${VERSION} \
    -n kadras-system \
    --values-file values.yml
  ```

### Values

The RabbitMQ Operator package has the following configurable properties.

<details><summary>Configurable properties</summary>

| Config | Default | Description |
|-------|-------------------|-------------|
| `logging.level` | `info` | The Operator log level. Valid options are `info` and `debug`. |

</details>

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
