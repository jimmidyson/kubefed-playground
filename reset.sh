#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. $(dirname ${BASH_SOURCE})/util.sh

export KUBECONFIG=$(dirname ${BASH_SOURCE})/kubefed-kubeconfig.yml

export DEMO_AUTO_RUN=1
export DEMO_RUN_FAST=1

desc "Cleaning up demo namespace"
run "kubectl delete namespace demos --ignore-not-found"
run "kubectl apply -f $(relative demo-namespace.yaml)"

tmux kill-session -t my-session || true
