#!/bin/bash
#
# FILE:         install
# AUTHOR:       Sang Han
# VERSION:      1.0.0rc
# DESCRIPTION   Install utility for dotfile configs
# DEPENDS:      Dotfiles 

usage() {
    cat <<- EOF
    $(basename $0) [-h help]

    Install utility for dotfile configs

    AUTHOR:     Sang Han
    YEAR:       2013
    VERSION:    1.0.0rc

    -h [help]
        Outputs usage directions


EOF
    exit 0
}

# Parse Options
while getopts ":h" OPTION; do
    case ${OPTION} in
        h) usage
            ;;
        ?) echo "Invalid option: -${OPTARG}" >&2
           exit 1
            ;;
    esac
done
    shift $(($OPTIND-1))

main() {
    return
}

if [[ "$0" == ${BASH_SOURCE} ]]; then
    main
fi
