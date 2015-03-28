#!/bin/bash
# Build:
#
# ::: build  :::  Build sprug
#

build_cmd() {
    local BUILDROOT=${SPRUG_DIR}/buildroot
    local CONFIG=${CONFIG_DIR}/buildroot.config

    if [ ! -f ${CONFIG} ]; then
        error "Invalid config: ${CONFIG}"
        return 1
    fi

    message "Build started: $(date +%G-%m-%d-%H:%M:%S)"
    rm -f ${BUILDROOT}/.config
    env -i - TERM=${TERM} HOME=${HOME} PATH=${PATH} \
        make -C ${BUILDROOT} distclean > /dev/null 2>&1
    sed -e "s!%%SPRUG_DIR%%!${SPRUG_DIR}!" < ${CONFIG} > \
        ${BUILDROOT}/.config
    env -i - TERM=${TERM} HOME=${HOME} PATH=${PATH} \
        make -C ${BUILDROOT}
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        error "Build failed: $(date +%G-%m-%d-%H:%M:%S)"
        return 1
    fi
    message "Build completed: $(date +%G-%m-%d-%H:%M:%S)"
}
