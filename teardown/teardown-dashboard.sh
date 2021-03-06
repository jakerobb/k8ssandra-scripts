#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source common.sh

echo -e "${BOLDBLUE}Tearing down kube-dashboard...${NOCOLOR}"

echo -e "\n${BOLDBLUE}Deleting service account with access to the dashboard...${NOCOLOR}"
cat <<EOF | kubectl delete -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl delete -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-user
  namespace: kubernetes-dashboard
EOF

echo -e "\n${BOLDBLUE}Deleting kubernetes-dashboard...${NOCOLOR}"
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml

