# Homelab Helm Repository

Welcome to my Homelab Helm Repository! This repository contains multiple Helm charts for deploying various applications and services on Kubernetes. Each chart is designed to provide a streamlined deployment process with configurable options to suit different use cases.

## Available Charts

### 1. Generic Kubernetes Service Chart

This chart is for deploying generic Kubernetes services that do not require much outside of deployment, service, and ingress resources. It is a slightly modified base Helm chart to include environment variables and secrets on deployment resources.

- [Usage Guide](charts/homelab-charts/README.md)
- Example values file: [full-deployment.yaml](charts/homelab-charts/tests/full-deployment.yaml)

## Contributing

If you would like to contribute to this Helm chart repository, please fork the repository, make your changes, and submit a pull request. We welcome contributions in the form of bug fixes, new features, or improvements to existing charts.

Before submitting a pull request, please make sure to test your changes locally and ensure that they follow the guidelines outlined in the CONTRIBUTING.md file.