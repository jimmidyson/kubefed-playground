#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. $(dirname ${BASH_SOURCE})/util.sh

export DEMO_AUTO_RUN=1
export DEMO_RUN_FAST=1

desc "Nuke it all"
readonly CLUSTERS=('cluster1' 'cluster2' 'cluster3' 'cluster4')
for CLUSTER in ${CLUSTERS[@]}; do
  run "kind delete cluster --name ${CLUSTER} || true"
done
tmux kill-session -t my-session >/dev/null 2>&1
