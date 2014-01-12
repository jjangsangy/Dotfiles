#!/bin/bash
#===============================================================================
#
#          FILE: link_files.sh
#
#         USAGE: ./link_files.sh
#
#   DESCRIPTION: links files to home directory
#
#       OPTIONS: -h [help] -a [all] -b [bash] -t [test]
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
    printf "symlink library cannot be found at ${LIB_SYMLINK}\n" >&2
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
    -a [all]
        Creates symlinks for all files
    -b [bash]
        Creates symlink for only bash specific files
    -t [test]
        Runs internal unit tests

END_DOC

exit 0
}

test_global() {
    printf "\$TEST is %s\n" "${TEST}"
    printf "\$PROGDIR is %s\n" "${PROGDIR}"
    printf "\$PROGNAME is %s\n" "${PROGNAME}"
    printf "\$LIB_SYMLINK is %s\n" "${LIB_SYMLINK}"
}

main() {
    link foo bar baz qux
}

# Parse Options
declare -i TEST=0
while getopts ":htab" OPTION; do
    case ${OPTION} in
        h) usage
            ;;
        a) LINK_ALL=("aliases" "path" "$LINK_BASH[@]")
            ;;
        b) LINK_BASH=1
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
    ((TEST==1)) && test_global
    main
fi
