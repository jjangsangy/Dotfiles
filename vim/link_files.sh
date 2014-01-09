#!/bin/bash
#===============================================================================
#
#          FILE: link_files.sh
#
#         USAGE: ./link_files.sh
#
#   DESCRIPTION: links files to home directory
#
#       OPTIONS: -h [help] -t [test]
#        AUTHOR: Sang Han, shan@calient.net
#       COMPANY: Calient Technologies
#       CREATED: 01/09/2014
#      REVISION: 1.0.0
#===============================================================================

# Global Variables
PROGNAME=$(basename "${BASH_SOURCE}")
PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILELIST=("vimrc" "vimrc.local" "vimrc.bundles" "vimrc.bundles.local")

usage() {
    cat <<- END_DOC

    link_files.sh   [ -h help] [ -t test ]

    DESCRIPTION: links files to home directory

    AUTHOR:      Sang Han, shan@calient.net
    COMPANY:     Calient Technologies
    CREATED:     01/09/2014
    REVISION:    1.0.0
    REQUIREMENTS: ---

    -h [help]
        Outputs usage directions
    -t [test]
        Runs internal unit tests

END_DOC
}

# Parse Options
declare -i TEST=0
while getopts ":ht" OPTION; do
    case ${OPTION} in
        h) usage
            ;;
        t) TEST=1
            ;;
        \?) echo "Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
    esac
done
    shift $(($OPTIND-1))

main() {
    for file in "${FILELIST[@]}"; do
        ln -s ${PROGDIR}/${file} ${HOME}/\.${file}
    done
}

if [[ "$0" == $BASH_SOURCE ]]; then
    main
fi
