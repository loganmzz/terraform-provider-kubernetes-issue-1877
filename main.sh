#!/usr/bin/env bash
set -o pipefail

basedir="$(cd "$(dirname "${BASH_SOURCE}")" >/dev/null; pwd)" || exit 1

TF_BIN="${TF_BIN:-terraform}"

function logs.println() {
    local date="$(date -Iseconds)"
    local line=''
    while read line; do
        echo "${date}  ${line}"
    done <<<"$*"
}

function tf.exec() {
    local step="$1"; shift
    local subcommand="$1"; shift
    local stdout="${basedir}/${step}.stdout.log"

    local command=("${TF_BIN}" "${subcommand}" -no-color "$@")
    logs.println "${command[@]}" &&
    TF_LOG_PATH="${basedir}/${step}.debug.log" "${command[@]}" >"${stdout}" 2>&1 || {
        local rc=$?
        logs.println "[ERROR] See ${stdout}"
        return $rc
    } >&2
}

function tf.step() {
    local version="$1"; shift
    local step="with_${version}"

    logs.println $'\n'"  =====  ${step}  =====" &&
    sed -ri "s/[^ ].*#MARKER/version = \"${version}\" #MARKER/" "main.tf" &&

    tf.exec "${step}_00_init"  init  -upgrade                                  &&
    tf.exec "${step}_01_plan"  plan  -out "${basedir}/${step}.tfplan"          &&
    tf.exec "${step}_02_apply" apply -input=false "${basedir}/${step}.tfplan"  &&
    true
}

function main() {
    pushd "${basedir}" >/dev/null &&
    export TF_LOG=debug           &&
    tf.step '2.13.1'              &&
    tf.step '2.14.0'              &&
    logs.println $'\nSUCCESS'      ||
    logs.println $'\nFAILURE'
}

main "$@"
