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
#       CREATED: 01/09/2014
#      REVISION: 1.1.0
#       DEPENDS: lib/symlink.sh
#===============================================================================

# Global Variables
PROGNAME=$(basename "${BASH_SOURCE}")
PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_SYMLINK="$PROGDIR/lib/symlink.sh"

if [[ -r "$LIB_SYMLINK" ]]; then
    source "$LIB_SYMLINK"
else
    printf "symlink library cannot be found at ${LIB_SYMLINK}" >&2
    exit 1
fi

usage() {
    cat <<- END_DOC

    link_files.sh   [-h help] [-t test]

    DESCRIPTION: links files to home directory

    AUTHOR:      Sang Han, shan@calient.net
    COMPANY:     Calient Technologies
    CREATED:     01/09/2014
    REVISION:    1.1.0
    REQUIREMENTS: symlink.sh library

    -h [help]
        Outputs usage directions
    -t [test]
        Runs internal unit tests

END_DOC

exit 0
}

test_names() {
    printf "\$TEST is %s\n" "${TEST}"
    printf "\$FILELIST is %s\n" "${FILELIST[*]}"
    exit 1
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

if [[ "$0" == $BASH_SOURCE ]]; then
    printf "symlink library cannot be found at ${LIB_SYMLINK}" >&2
fi

