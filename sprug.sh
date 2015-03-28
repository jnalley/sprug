#!/bin/bash -e

export PATH=/usr/local/bin:/usr/local/sbin:/bin:/usr/sbin:/usr/bin:/sbin

# sb command
SPRUG_CMD="$(readlink -f $0)"

# exit with error
die () {
    echo -e "\n$@\n\n" ; exit 1
}

# require bash 4
[[ ${BASH_VERSINFO[0]} -ge 4 ]] || \
    die "${SPRUG_CMD##*/} requires BASH 4 or higher"

# directory containing this script
SPRUG_DIR="${SPRUG_CMD%/*}"

# sanity check
[[ -s ${SPRUG_DIR}/.config ]] || \
    die "Missing ${SPRUG_DIR}/.config"

# check for required programs
check_requirements() {
    local REQUIRED=(
       bc g++ gcc git unzip curl python
    )

    local status=0
    for REQ in ${REQUIRED[@]}; do
        if ! inpath ${REQ}; then
            error "Please install: ${REQ}"
            status=1
        fi
    done

    return ${status}
}

# load additional functions from files in ${SPRUG_DIR}
require() {
    local rc=0
    local INCLUDE="${1}"

    # if path does not begin with '/' it is
    # assumed to be relative to ${SPRUG_DIR}
    if [[ "${INCLUDE:0:1}" != "/" ]]; then
        INCLUDE="${SPRUG_DIR}/${1}"
    fi

    if [[ -r "${INCLUDE}" && -s "${INCLUDE}" ]]; then
        source "${INCLUDE}"
        rc=$?
    else
        rc=1
    fi

    [[ ${rc} -eq 0 ]] || \
        die "Failed to include required file: '${INCLUDE}'"
}

# print usage for commands
usage() {
    local SB=${SPRUG_CMD##*/}
    echo
    echo "Usage: ${SB%%.sh} <command> [options]"
    echo
    echo "Commands:"
    for FILE in ${SPRUG_DIR}/scripts/sprug.d/*.sh; do
        local CMD=$(egrep '^# ::: ' ${FILE})
        CMD=${CMD#\# ::: }
        local SYNTAX=${CMD%%:::*}
        echo -n "  ${SYNTAX}"
        for ((i=1;i<15-${#SYNTAX};++i)); do
            echo -n " "
        done
        echo " - ${CMD##*:::}"
    done
    echo
}

# parse input
for CMD in ${SPRUG_DIR}/scripts/sprug.d/*.sh; do
    CMD=${CMD##*/}
    CMD=${CMD%%.sh}
    case "$1" in
        --${CMD}|${CMD}) COMMAND=${1#--} ; shift ; break ;;
    esac
done

# print help and exit if no command was given
[[ -z ${COMMAND} ]] && usage && exit 1

# set directory for temporary files
export TMPDIR=${SPRUG_DIR}/tmp

cleanup() {
    # cleanup temporary files
    rm -rf --preserve-root ${TMPDIR}
}

# exit with error status on CTRL-C
trap 'cleanup ; exit 1' INT
trap 'cleanup' EXIT

# load global configuration
require ${SPRUG_DIR}/.config

# validate that the path variables are set
# (it's ok if the directories don't exist yet)
for DIR in DOWNLOAD_DIR; do
    if [[ -z "${!DIR}" ]]; then
        echo "\${${DIR}} is not set - check sprug.config"
        exit 1
    fi
done

# load helper functions
require scripts/helpers.sh

# check for required programs
check_requirements || exit 1

# load command definition and execute command
require scripts/sprug.d/${COMMAND}.sh && ${COMMAND}_cmd $@

# vim: ft=sh:ts=4:sw=4
