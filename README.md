# K8ssandra Scripts

This collection of scripts streamlines the process of developing and testing [K8ssandra](https://k8ssandra.io). To minimize the "magic" and maximize learning,
most are designed to output the various `kubectl` and `helm` commands they invoke to do their jobs.

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
   * Note: if you plan to make contributions to k8ssandra, we recommend that you fork the repo and then clone your fork. See the 
     [contribution guidelines](https://github.com/k8ssandra/k8ssandra/blob/main/CONTRIBUTING.md) for more information.

### For Mac using Homebrew
The following command will install most of what you need.

    brew install go helm kind k3d kubectl jq python-yq

For other platforms, a similar string of packages pulled from your favorite package manager should do the trick. If you figure them out, please let us know via
issue or PR.

## Getting Started

1. Edit `config/env.sh` with the details of your setup.
   * See [config/README.md](config/README.md) for more details. 
2. Edit `config/custom-values.yaml` with whatever values overrides you wish to supply to Helm.
   * The file can be empty, but errors will occur if it does not exist.
   * Note that `config/env.sh` specifies the path to this file; if you change the path there, create or edit that file instead.
   * See [config/README.md](config/README.md) for more details.
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
* The `-p` option, for "peacemeal", tears down individual components manually before destroying the environment. Without this option, we skip right to deleting
  the cluster.


### Setup and Installation
#### setup-dashboard.sh
* Installs [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) and an appropriate ServiceAccount and ClusterRoleBinding

#### setup-helm.sh
* Ensures that Helm is configured with the necessary repos and that they are updated

#### setup-kind.sh
* Creates a kind cluster

#### setup-k3d.sh
* Creates a k3d cluster

#### setup-k8ssandra.sh
* Invokes Helm to install k8ssandra into your cluster.

#### setup-metrics.sh
* Installs the Metrics Server into your cluster.

#### setup-traefik.sh
* Invokes Helm to install [Traefik](https://traefik.io/) ingress into your cluster.

### Teardown
#### teardown-dashboard.sh
* Invokes kubectl to remove Kubernetes Dashboard from your cluster.

#### teardown-kind.sh
* Deletes your kind cluster.

#### teardown-k3d.sh
* Deletes your k3d cluster.

#### teardown-k8ssandra.sh
* Invokes Helm to uninstall k8ssandra from your cluster.

#### teardown-metrics.sh
* Invokes kubectl to remove the Metrics Server from your cluster.

#### teardown-traefik.sh
* Invokes Helm to uninstall Traefik from your cluster.


### Access
#### open-cqlsh.sh
Retrieves the superuser username and password, creates an appropriate port-forward (or, if ingress is enabled for Cassandra directly or via Stargate, uses 
that), then launches cqlsh. The port-forward, if one was used, terminates automatically when you exit cqlsh.

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
Creates an appropriate port-forward (or, if ingress is enabled for Stargate GraphQL, uses that), and directs you to the URL you should use to access the Playground. 
If you are on a Mac, it will launch the URL in your default browser automatically.

### Run
#### stargate-load-test.sh
Sends a barrage of REST requests to the Stargate API. 
Usage: `run/stargate-load-test.sh -n 5 10`
In the above example, the script will spawn five clones of itself, and each clone will send ten REST requests. Upon conclusion, you'll get a report with the 
time taken, the total number of requests sent, and the requests per second. You'll also get a collated summary of responses for all requests sent. 

Note: the data model in use for this test is very simple. Each process repeatedly updates a single column on a single row. There is much that could be done to 
improve upon this from a load test standpoint.

#### unit-tests.sh, integration-tests.sh
Runs the unit test suite or the integration test suite, respectively. 
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

### Monitoring
#### pod-events.sh
Usage: `monitoring/pod-events.sh [podName]` \
Example: `monitoring/pod-events.sh k8ssandra-dc1-stargate-85948dc948-gcbqb` 

This script prints the Events that Kubernetes has tracked against the specified pod. If you do not specify a pod, it will print a list of pods in the namespace.

#### service-pod-events.sh
Usage: `monitoring/service-pod-events.sh [serviceName]` \
Example: `monitoring/service-pod-events.sh k8ssandra-dc1-stargate-service` 

This script prints the Events that Kubernetes has tracked against the pods that match the specified service's selector. If you do not specify a service, 
it will print a list of services in the namespace. For each pod, it also prints the Created timestamp and the pod's Conditions. Pods are listed from oldest to 
newest.

#### watch.sh
Usage: `utils/watch.sh [resourceType]` \
Example: `utils/watch.sh` \
Example: `utils/watch.sh deployments` \
Example: `utils/watch.sh all`

This script simply watches the target namespace for a resource type of your choosing. It is useful for monitoring setup progress and watching for telltale
problem indications (e.g. CrashLoopBackoff and high restart counts). If you don't provide a resource type, it will use `pods`.

#### watch-service-events.sh
Usage: `monitoring/watch-service-events.sh [serviceName]` \
Example: `monitoring/watch-service-events.sh k8ssandra-dc1-stargate-service` 

This script is shorthand for `watch -cd service-pod-events.sh [serviceName]`, plus some small niceties. If you do not specify a service, it will print a list
of services in the namespace.


### Utilities
#### debug-templates.sh
Usage: `utils/debug-templates.sh ['template file path']`

Outputs the Helm templates that would be generated and installed by `setup-k8ssandra.sh` (helm install) or `update-k8ssandra.sh` (helm upgrade). If a template
file path is specified, it will be passed to `helm template --debug` via the `--show-only` option. The template file path should be specified relative to the 
chart, i.e. `utils/debug-templates.sh templates/stargate/stargate.yaml`. If you invoke it from the chart directory, you might be able to take advantage of your 
shell's autocomplete functionality.

#### get-credentials.sh
This script retrieves the k8ssandra superuser credentials and prints them to your console.

#### get-value.sh
Usage: `utils/get-value.sh '.some.value'` 

This script checks your values file for a specified value. If found, it will print the value. If not found, it will fall back to the chart's default values and
print that.

#### resume-cassandra.sh
Usage: `utils/resume-cassandra.sh [datacenter]` \
Example: `utils/resume-cassandra.sh 'dc2'` 

This script resumes a CassandraDatacenter that has previously been stopped (e.g. by using stop-cassandra.sh). If a datacenter is not specified, defaults to `dc1`.

#### scale-cassandra.sh
Usage: `utils/scale-cassandra.sh [-d datacenter] [size]` \
Example: `utils/get-value.sh -d 'dc2'` (outputs the current size of the `dc2` datacenter)\
Example: `utils/get-value.sh 5` (sets the size of `dc1` to five nodes).\
Example: `utils/get-value.sh -d 'dc2' 7` (sets the size of `dc2` to seven nodes) 

This script scales the number of nodes in a CassandraDatacenter, or reports the current scale. If a datacenter is not specified, defaults to `dc1`.

#### stop-cassandra.sh
Usage: `utils/stop-cassandra.sh [datacenter]` \
Example: `utils/stop-cassandra.sh 'dc2'` 

This script initiates a graceful shutdown of the Cassandra nodes in a CassandraDatacenter. If a datacenter is not specified, defaults to `dc1`.

#### wait-for-ready.sh
This script waits for Cassandra and Stargate (if enabled) to be fully online and ready.

## Global Options and Behaviors

By default, all scripts use colorized output, unless stdout is not a terminal (tty), e.g. if the script's output is being piped. 

All scripts accept the following options:

| Option        | Description |
| ------------- | ----------- |
| --nocolor     | Disable colorized output regardless of stdout's tty-ness. |
| --color       | Enable colorized output regardless of stdout's tty-ness. |
| -n namespace  | Use the specified namespace instead of the one specified in the values file. Note that some scripts might not perform correctly when using an alternate namespace. | 
| -d datacenter | Use the specified datacenter instead of the default ("dc1" by default unless you have custom topology, in which case it's whichever datacenter is listed first). Not all scripts make use of this value. | 


## Todo:
* Update common.sh to detect color-capable shells and disable color automatically.
* Add support for minikube.
* Add support for remote kubernetes clusters (i.e. just assume kubectl is already configured) (note: setup-all and teardown-all will need some attention with 
  regard to creation and destruction of the cluster) for this.
* Add support for using k8ssandra from the helm repo instead of from a repo clone (note: setup-kind.sh depends on a kind config file from k8ssandra's docs)
* Update setup-dashboard.sh and teardown-dashboard.sh to use Helm charts.
* Add support for nginx for ingress
* Add `-c` option to unit-tests.sh and integration-tests.sh to add coverage
* Use `set -x` in more scripts
