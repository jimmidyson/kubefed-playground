#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly reset=$(tput sgr0)
readonly green=$(tput bold; tput setaf 2)
readonly yellow=$(tput bold; tput setaf 3)
readonly blue=$(tput bold; tput setaf 6)
readonly timeout=$(if [ "$(uname)" == "Darwin" ]; then echo "1"; else echo "0.1"; fi)
readonly sedi=$(if [ "$(uname)" == "Darwin" ]; then echo "-i ''"; else echo "-i"; fi)

function desc() {
    maybe_first_prompt
    echo "$blue# $@$reset"
    prompt
}

function prompt() {
    echo -n "$yellow\$ $reset"
}

started=""
function maybe_first_prompt() {
    if [ -z "$started" ]; then
        prompt
        started=true
    fi
}

# After a `run` this variable will hold the stdout of the command that was run.
# If the command was interactive, this will likely be garbage.
DEMO_RUN_STDOUT=""

function run() {
    maybe_first_prompt
    rate=25
    if [ -n "${DEMO_RUN_FAST:-}" ]; then
      rate=1000
    fi
    echo "$green$1$reset" | pv -qL $rate
    if [ -n "${DEMO_RUN_FAST:-}" ]; then
      sleep 0.5
    fi
    OFILE="$(mktemp -t $(basename $0).XXXXXX)"
    set +e
    script -eq -c "$1" -f "$OFILE"
    r=$?
    read -d '' -t "${timeout}" -n 10000  # clear stdin
    set -e
    prompt
    if [ -z "${DEMO_AUTO_RUN:-}" ]; then
      read -s
    fi
    DEMO_RUN_STDOUT="$(tail -n +2 $OFILE | sed 's/\r//g')"
    return $r
}

function relative() {
    for arg; do
        echo "$(realpath $(dirname $(which $0)))/$arg" | sed "s|$(realpath $(pwd))|.|"
    done
}

readonly CLUSTERS=('cluster1' 'cluster2' 'cluster3' 'cluster4')

function check_resources() {
    local -r TYPE=$1
    local -r INSTANCE=$2
    local -r NAMESPACE=${3:-}

    echo

    for CLUSTER in "${CLUSTERS[@]}"; do
        if [[ -z "${NAMESPACE}" ]]; then
            printf "%-10s %-20s\n" "${CLUSTER}:" $(kubectl --context=${CLUSTER}-admin@${CLUSTER} get ${TYPE} ${INSTANCE} -o name --ignore-not-found)
        else
            printf "%-10s %-20s\n" "${CLUSTER}:" $(kubectl --context=${CLUSTER}-admin@${CLUSTER} get ${TYPE} ${INSTANCE} -n ${NAMESPACE} -o name --ignore-not-found)
        fi
    done
}

trap "echo" EXIT
