#!/bin/bash
# Builds ami using nubis builder

PREFIX=$(dirname $0)
if [[ -f ${PREFIX}/variables.sh ]]; then
    . ${PREFIX}/variables.sh
else
    echo "Please configure variables.sh"
fi

nubis_build_dir=${BASE_DIR}/nubis-builder
export PATH="${nubis_build_dir}/bin:$PATH"

nubis-builder build
