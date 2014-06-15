#!/usr/bin/env bash

LOG_PATH="${1}"
HSA=$(printf "2%.4s" "${LOG_PATH##*\ 2}")
REMAP="/Users/jjangsangy/Projects/wiggle/data/wiggle_remap/"

main() {
    local destination="${REMAP}${HSA}/Raw Data"

    if [[ $HSA =~ [0-9]{5} ]]; then
        test -d "${destination}" || mkdir -p "${destination}"
        cp -a "${LOG_PATH}" "${destination}" && rm "${LOG_PATH}"
        echo "${HSA} Remapped"
    fi

    return 0
}

if [[ "$0" = "${BASH_SOURCE[0]}" ]]; then
    #main
    awk -F "," '/Mirror ID:/ {print $2}' "${LOG_PATH}"
fi
