#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. $(dirname ${BASH_SOURCE})/util.sh

desc "Configuring clusters with kind"

KUBECONFIG=""
for CLUSTER in ${CLUSTERS[@]}; do
  CLUSTER_KUBECONFIG="$(kind get kubeconfig-path --name="${CLUSTER}")"
  if [ -f "${CLUSTER_KUBECONFIG}" ]; then
    desc "${CLUSTER} already exists"
  else
    desc "Creating ${CLUSTER}"
    run "kind create cluster --name="${CLUSTER}" --image=kindest/node:v1.15.3"
    desc "Updating kubeconfig for ${CLUSTER}"
    run "sed ${sedi} \"s/kubernetes-admin/${CLUSTER}-admin/g\" $(kind get kubeconfig-path --name="${CLUSTER}")"
  fi
  if [ -n "${KUBECONFIG}" ]; then
    KUBECONFIG="${KUBECONFIG}:"
  fi
  KUBECONFIG="${KUBECONFIG}${CLUSTER_KUBECONFIG}"
done

desc "Merging federated cluster kubeconfigs"
run "KUBECONFIG=\"${KUBECONFIG}\" kubectl config view --flatten --merge > $(dirname ${BASH_SOURCE})/kubefed-kubeconfig.yml"
export KUBECONFIG=$(dirname ${BASH_SOURCE})/kubefed-kubeconfig.yml
ROOT_CLUSTER_CONTEXT=${CLUSTERS[0]}-admin@${CLUSTERS[0]}
desc "Setting kubeconfig root cluster context"
run "kubectl config use-context ${ROOT_CLUSTER_CONTEXT}"
desc "Updating federated clusters API server addresses"
for CLUSTER in ${CLUSTERS[@]}; do
  CLUSTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${CLUSTER}-control-plane")
  run "kubectl config set-cluster ${CLUSTER} --server=https://${CLUSTER_IP}:6443"
done

KUBEFED_VERSION="0.1.0-rc6"

desc "Installing tiller"

desc "Checking tiller serviceaccount"
if ! run "kubectl get serviceaccounts tiller -n kube-system &> /dev/null"; then
  desc "Tiller service account does not exist - creating"
  run "kubectl apply -f $(dirname ${BASH_SOURCE})/tiller-serviceaccount.yaml"
fi

desc "Checking if tiller is installed"

if ! run "helm ls &> /dev/null"; then
  desc "Tiller is not installed - installing..."
  run "helm init --service-account tiller"
fi

desc "Waiting for tiller..."
run "kubectl wait --for=condition=ready pods -l app=helm,name=tiller -n kube-system"

desc "Checking for kubefed..."
run "helm list kubefed --deployed -q"
if [ -z "$(helm list kubefed --deployed -q)" ]; then
  desc "kubefed is not installed - installing..."
  run "helm repo add kubefed-charts https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/charts"
  run "helm install kubefed-charts/kubefed --name kubefed --version="${KUBEFED_VERSION}" --namespace kube-federation-system"
fi

desc "Waiting for kubefed..."
run "kubectl wait --for=condition=available deployments/kubefed-controller-manager -n kube-federation-system"
run "kubectl wait --for=condition=available deployments/kubefed-admission-webhook -n kube-federation-system"

desc "Showing available kubefed API resources"
run "kubectl api-resources --api-group core.kubefed.io"

desc "And current federatedtypeconfigs"
run "kubectl get federatedtypeconfigs --all-namespaces"

desc "Setting up kubefed config"
run "kubectl apply -f $(dirname ${BASH_SOURCE})/kubefed-config.yaml"

desc "Joining clusters to kubefed"
for CLUSTER in ${CLUSTERS[@]}; do
  run "kubefedctl join "${CLUSTER}" \
    --cluster-context "${CLUSTER}-admin@${CLUSTER}" \
    --host-cluster-context "${ROOT_CLUSTER_CONTEXT}" \
    --host-cluster-name "${CLUSTERS[0]}" \
    --v=2"
done

desc "Waiting for clusters to be ready for federation"
run "kubectl wait --for=condition=ready -n kube-federation-system kubefedclusters --all"
