# K8ssandra Scripts

This is a collection of scripts I've built to streamline the process of developing and using K8ssandra.

## Prerequisites
* The following software installed:
   * bash-compatible shell (the scripts use `#!/usr/bin/env bash`)
   * Docker
   * helm 3
   * kind and/or k3d
   * kubectl
   * jq
   * yq
* Docker configured with sufficient resources (recommend: 16GB RAM and at least four CPU cores)
* A clone of the k8ssandra repo

## Getting Started

1. Edit `config/env.sh` with the details of your setup.
2. Edit `config/custom-values.yaml` with whatever values overrides you wish to supply to Helm.
   * The file can be empty, but errors will occur if it does not exist.
   * Note that `config/env.sh` specifies the path to this file; if you change the path there, create or edit that file instead.
3. To set up a complete cluster from scratch, run `setup-all.sh`.

## Scripts

### The Big Three
#### setup-all.sh
Creates and starts everything you need from scratch. When complete, you'll have:
* Helm configured and updated with all of the necessary repos
* A running Kubernetes environment in Kind or k3d
* kube-dashboard installed
* Traefik installed and configured (if you have enabled ingress)
* k8ssandra installed

The script waits for the Cassandra cluster to be ready, and if Stargate is enabled, waits for that to come up next. When everything is ready, it retrieves the 
superuser credentials and outputs them to the console.

#### update-k8ssandra.sh
Updates the k8ssandra installation with the current value overrides. This is shorthand for the correct and complete `helm upgrade` command.

#### teardown-all.sh
Usage: `./teardown-all.sh [-p]`
* Uninstalls everything and tears down the Kubernetes environment.
* The '-p' option, for "peacemeal", tears down individual components manually before destroying the environment. Without this option, we skip right to deleting
  the cluster.


### Setup and Installation
#### setup-dashboard.sh
* Installs kube-dashboard and an appropriate ServiceAccount and ClusterRoleBinding

#### setup-helm.sh
* Ensures that Helm is configured with the necessary repos and that they are updated

#### setup-k3d.sh
* Creates a k3d cluster
* 

#### setup-k8ssandra.sh
#### setup-kind.sh
#### setup-traefik.sh

### Teardown
#### teardown-dashboard.sh
#### teardown-k3d.sh
#### teardown-k8ssandra.sh
#### teardown-kind.sh
#### teardown-traefik.sh

### Access
#### open-dashboard.sh
Retrieves a login token, creates an appropriate port-forward, and directs you to the URL you should use to access the dashboard. If you are on a Mac, it will
launch the URL in your default browser automatically.

#### open-grafana.sh
#### open-prometheus.sh
#### open-traefik.sh

### Tests
#### stargate-load-test.sh
Sends a barrage of REST requests to the Stargate API. 
Usage: `tests/stargate-load-test.sh -n 5 10`
In the above example, the script will spawn five clones of itself, and each clone will send ten REST requests. Upon conclusion, you'll get a report with the 
time taken, the total number of requests sent, and the requests per second. You'll also get a collated summary of responses for all requests sent. 

Note: the data model in use for this test is very simple. Each process repeatedly updates a single column on a single row. There is much that could be done to 
improve upon this from a load test standpoint.

#### helm-debug.sh


## Todo:
* Update common.sh to detect color-capable shells and disable color automatically.
* Add support for minikube.
* Add support for remote kubernetes clusters (i.e. just assume kubectl is already configured) (note: setup-all and teardown-all will need some attention with 
  regard to creation and destruction of the cluster) for this.
* Add support for using k8ssandra from the helm repo instead of from a repo clone (note: setup-kind.sh depends on a kind config file from k8ssandra's docs)
* Update setup-dashboard.sh and teardown-dashboard.sh to use Helm charts.
