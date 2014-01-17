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
#        AUTHOR: Sang Han
#       CREATED: 01/09/2014
#      REVISION: 1.2.0
#===============================================================================

# Global Variables
PROGNAME=$(basename "${BASH_SOURCE}")
PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILELIST=("aliases" "path" "bash/profile" "bash/jump.sh" "bash/inputrc" "bash/dircolors" "bash/dircolors_light" "bash/dircolors_dark" "bash/prompt.sh")

usage() {
    cat <<- END_DOC

    link_files.sh   [-h help] [-t test]

    DESCRIPTION: links files to home directory

    AUTHOR:      Sang Han
    CREATED:     01/09/2014
    REVISION:    1.2.0
    REQUIREMENTS: ---

    -h [help]
        Outputs usage directions
    -t [test]
        Runs internal unit tests

END_DOC

exit 0
}

test_globals() {
    printf "\$TEST is %s\n" "${TEST}"
    printf "\$PROGNAME is %s\n" "${PROGNAME}"
    printf "\$PROGDIR is %s\n" "${PROGDIR}"
    printf "\$FILELIST is %s\n" "${FILELIST[*]}"
    return
}

test_source() {
    if [ -f "$LINK_SOURCE" ]; then
        printf "$(tput setaf 4)\$LINK_SOURCE$(tput sgr0) file exists at %s\n" "${LINK_SOURCE}"
    else
        printf "$(tput setaf 1)\$LINK_SOURCE$(tput sgr0) file does not exists at %s\n" "${LINK_SOURCE}"
    fi
}

test_dest() {
    if [ -f "$LINK_DEST" ]; then
        printf "$(tput setaf 4)\$LINK_DEST$(tput sgr0) file exists at %s\n\n" "${LINK_DEST}"
    else
        printf "$(tput setaf 1)\$LINK_DEST$(tput sgr0) file does not exists at %s\n\n" "${LINK_DEST}"
    fi
}

prompt_delete() {
    # Prompts the user authorization for deleting original file at $LINK_DEST.
    # After authorization is granted, file is deleted and replaced with
    # a symlink from $LINK_SOURCE
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
    # TODO: Add support for symlinking directories
    ln -s "${LINK_SOURCE}" "${LINK_DEST}"
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
    if (($TEST==1)); then
        # Test global variable names
        test_globals
    fi

    # Iterate through indexed array of files.
    # If file is located within a subdirectory, the name of parent is stripped
    for FILE in "${FILELIST[@]}"; do
        local LINK_SOURCE=${PROGDIR}/${FILE}
        local LINK_DEST=${HOME}/\.${FILE##*/}
        if (($TEST==1)); then
            # Test source and destination directory. Existing files
            # are highlighted blue and non-existing files are red.
            test_source
            test_dest
            continue
        fi
        link_files >/dev/null 2>&1 || prompt_delete
    done
}

if [[ "$0" == $BASH_SOURCE ]]; then
    main
fi
