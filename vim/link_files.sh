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
#      REVISION: 1.1.0
#===============================================================================

# Global Variables
PROGNAME=$(basename "${BASH_SOURCE}")
PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILELIST=("vimrc" "vimrc.local" "vimrc.bundles" "vimrc.bundles.local")

usage() {
    cat <<- END_DOC

    link_files.sh   [-h help] [-t test]

    DESCRIPTION: links files to home directory

    AUTHOR:      Sang Han, shan@calient.net
    COMPANY:     Calient Technologies
    CREATED:     01/09/2014
    REVISION:    1.1.0
    REQUIREMENTS: ---

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

prompt_delete() {
    read -p "File $LINK_DEST already exists, would you like to delete it? \
        [Yy]/[Nn]:  " RESPONSE

    if [[ $RESPONSE =~ [Yy] ]]; then
        rm "${LINK_DEST}"
        link_files
    else
        return
    fi

}

link_files() {
    ln -s "${LINK_SOURCE}" "${LINK_DEST}"
}

main() {
    # Unit Test Switch
    if (($TEST==1)); then
        test_names
    fi

    for FILE in "${FILELIST[@]}"; do
        local LINK_SOURCE=${PROGDIR}/${FILE}
        local LINK_DEST=${HOME}/\.${FILE}
        link_files >/dev/null 2>&1 || prompt_delete
    done
}

if [[ "$0" == $BASH_SOURCE ]]; then
    main
fi
