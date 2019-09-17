#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ORIGINAL_DEMO_AUTO_RUN=${DEMO_AUTO_RUN:-}
export DEMO_AUTO_RUN=1
ORIGINAL_DEMO_RUN_FAST=${DEMO_RUN_FAST:-}
export DEMO_RUN_FAST=1

. $(dirname ${BASH_SOURCE})/create-federated-clusters.sh

echo
desc "Federation configured... now the real demo begins!"
echo

if [ -z "${ORIGINAL_DEMO_AUTO_RUN}" ]; then
  unset DEMO_AUTO_RUN
fi
if [ -z "${ORIGINAL_DEMO_RUN_FAST}" ]; then
  unset DEMO_RUN_FAST
fi
