#!/usr/bin/env bash
# note: this file is intended to be sourced by common.sh

# Customize your setup here

# Absolute path to your K8ssandra repo
K8SSANDRA_DIR=/path/to/k8ssandra

# relative to the k8ssandra-scripts directory
VALUES_FILE=config/custom-values.yaml

# Name you want to use for your Helm installation
RELEASENAME=k8ssandra

# Target environment. Supported values are "kind" and "k3d".
KUBE_ENV=kind

# Version of Kubernetes. Supported values vary by target environment; see setup-kind.sh and setup-k3d.sh for supported values.
KUBE_VERSION=1.19.7

# If true, when used on Mac, some long-running scripts will announce their completion aloud, allowing the user the freedom to step away.
AUDIBLE_ANNOUNCEMENTS=true

# If true, setup-all.sh will also include a Traefik installation for ingress
INSTALL_TRAEFIK=true
