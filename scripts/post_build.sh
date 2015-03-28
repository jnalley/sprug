#!/bin/bash

TARGET=${1}
SPRUG_DIR=${2}

die () {
    echo $@ ; exit 1
}

# sanity checks
[[ -d ${TARGET} ]] || die "Missing target directory!"

# ${TARGET} must be a subdirectory of ${SPRUG_DIR}
case ${SPRUG_DIR}/ in
    ${TARGET}*) die "${TARGET} is not a subdirectory of ${SPRUG_DIR}" ;;
esac

# add version to image
VERSION="$(git rev-parse --verify --short HEAD)"
[[ -z $(git diff-index --name-only HEAD) ]] || VERSION="${VERSION}-dirty"

mkdir -p ${TARGET}/etc && \
    echo ${VERSION} > ${TARGET}/etc/version

find ${TARGET} -type f -name .keep -exec rm -f {} \;

# vim: ft=sh:ts=4:sw=4
