#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. $(dirname ${BASH_SOURCE})/../util.sh

export KUBECONFIG=$(dirname ${BASH_SOURCE})/../kubefed-kubeconfig.yml

desc "Federate a secret to labelled clusters"

desc "Listing secret in federated clusters"

check_resources secrets mysecret demos

desc "Configure federated namespace"
run "kubectl apply -f $(relative ../namespace/federated-namespace.yaml) -n demos"

desc "Waiting for namespace to be propagated"
run "kubectl wait --for=condition=propagation -n demos federatednamespaces/demos"

ORIGINAL_DEMO_AUTO_RUN=${DEMO_AUTO_RUN:-}
export DEMO_AUTO_RUN=1
ORIGINAL_DEMO_RUN_FAST=${DEMO_RUN_FAST:-}
export DEMO_RUN_FAST=1

if [ -z "${ORIGINAL_DEMO_AUTO_RUN}" ]; then
  unset DEMO_AUTO_RUN
fi
if [ -z "${ORIGINAL_DEMO_RUN_FAST}" ]; then
  unset DEMO_RUN_FAST
fi

desc "Configure federated secret with overrides"
run "kubectl apply -f $(relative federated-secret.yaml) -n demos"

desc "A small pause..."
sleep 5
desc "Waiting for secret to be propagated"
run "kubectl wait --for=condition=propagation -n demos federatedsecrets/mysecret"

desc "Checking override values"
echo
for CLUSTER in "${CLUSTERS[@]}"; do
    printf "%-10s %-20s\n" "${CLUSTER}:" $(kubectl get secret mysecret -n demos --context=${CLUSTER}-admin@${CLUSTER} -o go-template --template '{{ index .data "username" }}' | base64 -d)
done
