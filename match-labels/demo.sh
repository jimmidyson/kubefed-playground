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

desc "Labelling target clusters"
readonly TEAMS=('finance' 'finance' 'marketing' 'product')
readonly PROVIDERS=('aws' 'gcp' 'aws' 'aws')
for i in ${!CLUSTERS[@]}; do
    run "kubectl label --overwrite -n kube-federation-system kubefedclusters "${CLUSTERS[i]}" team=${TEAMS[i]} provider=${PROVIDERS[i]}"
done

if [ -z "${ORIGINAL_DEMO_AUTO_RUN}" ]; then
  unset DEMO_AUTO_RUN
fi
if [ -z "${ORIGINAL_DEMO_RUN_FAST}" ]; then
  unset DEMO_RUN_FAST
fi

desc "Configure federated secret to AWS labelled clusters"
run "kubectl apply -f $(relative federated-secret-aws.yaml) -n demos"

desc "A small pause..."
sleep 5
desc "Waiting for secret to be propagated"
run "kubectl wait --for=condition=propagation -n demos federatedsecrets/mysecret"

desc "Listing secret in federated clusters - should not be in cluster 2"
check_resources secrets mysecret demos

desc "Configure federated secret to AWS and marketing labelled clusters"
run "kubectl apply -f $(relative federated-secret-aws-marketing.yaml) -n demos"

desc "A small pause..."
sleep 5
desc "Waiting for secret to be propagated"
run "kubectl wait --for=condition=propagation -n demos federatedsecrets/mysecret"

desc "Listing secret in federated clusters - should only be in cluster 3"
check_resources secrets mysecret demos

desc "Configure federated secret to AWS and marketing labelled clusters"
run "kubectl apply -f $(relative federated-secret-gcp-product.yaml) -n demos"

desc "A small pause..."
sleep 5
desc "Waiting for secret to be propagated"
run "kubectl wait --for=condition=propagation -n demos federatedsecrets/mysecret"

desc "Listing secret in federated clusters - should not be in any clusters"
check_resources secrets mysecret demos
