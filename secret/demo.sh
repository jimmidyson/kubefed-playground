#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. $(dirname ${BASH_SOURCE})/../util.sh

export KUBECONFIG=$(dirname ${BASH_SOURCE})/../kubefed-kubeconfig.yml

desc "Federate a secret to all clusters"

desc "Listing secret in federated clusters"

check_resources secrets mysecret demos

desc "Configure federated namespace"
run "kubectl apply -f $(relative ../namespace/federated-namespace.yaml) -n demos"

desc "Waiting for namespace to be propagated"
run "kubectl wait --for=condition=propagation -n demos federatednamespaces/demos"

desc "Configure federated secret to all clusters"
run "kubectl apply -f $(relative federated-secret.yaml) -n demos"

desc "A small pause..."
sleep 5
desc "Waiting for secret to be propagated"
run "kubectl wait --for=condition=propagation -n demos federatedsecrets/mysecret"

desc "Listing secret in federated clusters - should be in all clusters"
check_resources secrets mysecret demos
