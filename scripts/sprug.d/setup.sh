#!/bin/bash
# Setup:
#
# ::: setup  :::  Configure the buildroot
#

setup_cmd() {
    local TARBALL=${DOWNLOAD_DIR}/${BUILDROOT_URL##*/}
    local BUILDROOT=${SPRUG_DIR}/buildroot
    local BUILDTYPE=${1:-standard}

    # download tarball
    fetch ${BUILDROOT_URL} ${TARBALL} || return 1

    # get sha1sum
    SHA1SUM=$(sha1sum ${TARBALL})
    SHA1SUM=${SHA1SUM%% *}

    # verify sha1sum
    if [[ ${SHA1SUM} != ${BUILDROOT_SHA1} ]]; then
        error "Invalid sha1sum for ${BUILDROOT_URL}"
        return 1
    fi

    # unpack the tarball
    unpack ${TARBALL} ${BUILDROOT} || return 1

    # patch buildroot
    local PATCH
    local PBASE
    mkdir -p ${BUILDROOT}/.patched
    for PATCH in ${SPRUG_DIR}/patches/buildroot/*; do
        [[ -f ${PATCH} ]] || continue
        # patches for factory build
        [[ ${BUILDTYPE} != 'factory' && -z ${PATCH##factory-*} ]] && \
            continue
        PBASE=${BUILDROOT}/.patched/${PATCH##*/}
        if [[ -f ${PBASE} ]]; then
            if [[ $(stat -c '%Y' ${PATCH}) > $(stat -c '%Y' ${PBASE}) ]]; then
                message "${PATCH##*/} may be more recent than the applied version!"
            fi
            continue
        fi
        message "Applying ${PATCH}"
        if ! env -i - patch -d ${BUILDROOT} -p1 < ${PATCH}; then
            error "Failed to apply patch!"
            return 1
        fi
        touch ${PBASE}
    done

    local PACKAGE
    for PACKAGE in ${SPRUG_DIR}/package/*; do
        # skip non-directories
        [[ -d ${PACKAGE} ]] || continue
        local PKGNAME=${PACKAGE##*/}
        # skip if destination already exists
        [[ -d ${BUILDROOT}/package/${PKGNAME} || \
           -L ${BUILDROOT}/package/${PKGNAME} ]] && continue
        message "Installing ${PKGNAME}"
        if ! ln -svf ../../package/${PKGNAME} \
                ${BUILDROOT}/package/${PKGNAME}; then
            error "Failed to install ${PKGNAME}"
            return 1
        fi
    done
}
