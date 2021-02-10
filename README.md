# K8ssandra Scripts

This collection of scripts streamlinea the process of developing and testing [K8ssandra](https://k8ssandra.io).

## Prerequisites
* The following software installed:
   * bash-compatible shell (the scripts use `#!/usr/bin/env bash`)
   * Docker
   * Go
   * helm 3
   * kind and/or k3d
   * kubectl
   * jq
   * yq
* Docker configured with sufficient resources (recommend: 16GB RAM and at least four CPU cores)
* A clone of the [k8ssandra repo](https://github.com/k8ssandra/k8ssandra)

### For Mac using Homebrew
The following command will install most of what you need.

    brew install go helm kind k3d kubectl jq python-yq

For other platforms, a similar string of packages pulled from your favorite package manager should do the trick. If you figure them out, please let us know via
issue or PR.

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

#### setup-kind.sh
* Creates a kind cluster

#### setup-k3d.sh
* Creates a k3d cluster

#### setup-k8ssandra.sh
* Invokes Helm to install k8ssandra into your cluster.

#### setup-traefik.sh
* Invokes Helm to install Traefik ingress into your cluster.

### Teardown
#### teardown-dashboard.sh
* Uninstalls kube-dashboard from your cluster.

#### teardown-kind.sh
* Deletes your kind cluster.

#### teardown-k3d.sh
* Deletes your k3d cluster.

#### teardown-k8ssandra.sh
* Invokes Helm to uninstall k8ssandra from your cluster.

#### teardown-traefik.sh
* Invokes Helm to uninstall Traefik from your cluster.


### Access
#### open-dashboard.sh
Retrieves a login token, creates an appropriate port-forward, and directs you to the URL you should use to access the dashboard. If you are on a Mac, it will
launch the URL in your default browser automatically.

#### open-grafana.sh
Retrieves login credentials, creates an appropriate port-forward, and directs you to the URL you should use to access Grafana. If you are on a Mac, it will
launch the URL in your default browser automatically.

#### open-prometheus.sh
Creates an appropriate port-forward, and directs you to the URL you should use to access the Prometheus web UI. If you are on a Mac, it will launch the URL in
your default browser automatically.

#### open-traefik.sh
Directs you to the URL you should use to access the Traefik web UI. If you are on a Mac, it will launch the URL in your default browser automatically.

#### open-reaper.sh
Creates an appropriate port-forward (or, if ingress is enabled for Reaper, uses that), and directs you to the URL you should use to access the Reaper web UI. 
If you are on a Mac, it will launch the URL in your default browser automatically.

#### open-stargate-graphql-playground.sh
Creates an appropriate port-forward (or, if ingress is enabled for Stargate, uses that), and directs you to the URL you should use to access the Playground. 
If you are on a Mac, it will launch the URL in your default browser automatically.

### Run
#### stargate-load-test.sh
Sends a barrage of REST requests to the Stargate API. 
Usage: `run/stargate-load-test.sh -n 5 10`
In the above example, the script will spawn five clones of itself, and each clone will send ten REST requests. Upon conclusion, you'll get a report with the 
time taken, the total number of requests sent, and the requests per second. You'll also get a collated summary of responses for all requests sent. 

Note: the data model in use for this test is very simple. Each process repeatedly updates a single column on a single row. There is much that could be done to 
improve upon this from a load test standpoint.

#### unit-tests.sh
Runs the unit test suite. 
Usage: `run/unit-tests.sh ['test name regex']`
Runs the unit test suite, or a subset of it. The test name regex will match any substring of the concatenated strings passed to Describe(), Context(), and 
It() functions in the test spec. The script automatically prepends the regex with `(i?)`, making it case-insensitive.

For example, a test spec as follows would concatenate to `Verify CassandraDatacenter template by rendering it with options using only default options` (matching
what gets printed to the console), and that is the string which will be tested against the regex to determine whether that test will be included.

    var _ = Describe("Verify CassandraDatacenter template", func() {
	    Context("by rendering it with options", func() {
		    It("using only default options", func() {
                ...

For an example, try passing `Stargate` or `medusa`. 

#### debug-templates.sh
Usage: `utils/debug-templates.sh ['template file path']`
Outputs the Helm templates that would be generated and installed by `setup-k8ssandra.sh` (helm install) or `update-k8ssandra.sh` (helm upgrade). If a template
file path is specified, it will be passed to `helm template --debug` via the `--show-only` option. The template file path should be specified relative to the 
chart, i.e. `utils/debug-templates.sh templates/stargate/stargate.yaml`



## Todo:
* Update common.sh to detect color-capable shells and disable color automatically.
* Add support for minikube.
* Add support for remote kubernetes clusters (i.e. just assume kubectl is already configured) (note: setup-all and teardown-all will need some attention with 
  regard to creation and destruction of the cluster) for this.
* Add support for using k8ssandra from the helm repo instead of from a repo clone (note: setup-kind.sh depends on a kind config file from k8ssandra's docs)
* Update setup-dashboard.sh and teardown-dashboard.sh to use Helm charts.
* Add support for multiple / non-default datacenters (search for "dc1")
