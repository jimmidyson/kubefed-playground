#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. $(dirname ${BASH_SOURCE})/../util.sh

export KUBECONFIG=$(dirname ${BASH_SOURCE})/../kubefed-kubeconfig.yml

desc "Federate a namespace to all clusters"

desc "Listing namespace in federated clusters"

check_resources namespaces demos

desc "Configure federated namespace"
run "kubectl apply -f $(relative federated-namespace.yaml) -n demos"

desc "Waiting for namespace to be propagated"
run "kubectl wait --for=condition=propagation -n demos federatednamespaces/demos"

desc "Listing namespace in federated clusters"
check_resources namespaces demos
