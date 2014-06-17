#!/usr/bin/env bash
# ==============================================================================
usage() { cat <<- DOCUMENT

    usage: $PROGNAME [-h help] [-t test] [-f file]

    AUTHOR:      Sang Han
    CREATED:     01/09/2014
    REVISION:    1.3

    $COLOR DESCRIPTION:
        Program for automating users preferred login shell enviornment.
        Symbolically links the startup files located within dotfiles
        repository and links them to to users \$HOME variable prepended
        with a dot. If the startup file already and a collision occurs,
        user will be prompted for deletion.

    REQUIREMENTS:
        Program must be called while present working directory is within
        the root of the Dotfiles repository.

    OPTIONS:
        -h [help]
            Outputs usage directions
        -t [test]
            Runs internal unit tests
        -f [file]
            Reference external file

    EXAMPLES:
        Run unit tests and prints out all assigned values and variables
        ./${PROGNAME} -t

        Run program:
        ./$PROGNAME

        Use your own config file:
        ./$PROGNAME -f config_file

    TODO: Allow the usage of a configuration file to specified rather than
          just reading from global variables.
    TODO: Allow the option of copying the files rather than symbolic linking


	DOCUMENT
}
# ==============================================================================
# Global Variables
# ==============================================================================
readonly PROGNAME=$(basename "${BASH_SOURCE}")
readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Tests
# ==============================================================================
test_variables() {
    declare -a variables=(${*})
    for var in "${variables[@]}"; do
        printf "%30s = %s\n" \
            "$(tput setaf 9)\$${var}$(tput sgr0)" \
            "$(tput setaf 3)${!var}$(tput sgr0)"
    done
}

test_source() {
    if [ -f "$LINK_SOURCE" ]; then
        printf "$(tput setaf 4)\
            \$LINK_SOURCE\
                $(tput sgr0)\
                file exists at %s\n" \
            "${LINK_SOURCE}"
    else
        printf "$(tput setaf 1)\
            \$LINK_SOURCE\
                $(tput sgr0)\
                file does not exists at %s\n" \
            "${LINK_SOURCE}"
    fi
}

test_dest() {
    if [ -f "$LINK_DEST" ]; then
        printf "$(tput setaf 4)\
            \$LINK_DEST\
                $(tput sgr0)\
                file exists at %s\n\n" \
            "${LINK_DEST}"
    else
        printf "$(tput setaf 1)\
            \$LINK_DEST\
                $(tput sgr0)\
                file does not exists at %s\n\n" \
            "${LINK_DEST}"
    fi
}

function prompt_delete() {
# ===============================================================================
# Prompts the user authorization for deleting original file at $LINK_DEST.
# After authorization is granted, file is deleted and replaced with
# a symlink from $LINK_SOURCE
# ===============================================================================
    read -p "File $LINK_DEST already exists, would you like to delete it? \
        [Yy]/[Nn]:  " RESPONSE

    if [[ $RESPONSE =~ [Yy] ]]; then
        rm "${LINK_DEST}"
        link_files
    else
        return
    fi
}

function link_files() {
# ===============================================================================
# TODO: Add support for symlinking entire directories
# ===============================================================================
    ln -s "${LINK_SOURCE}" "${LINK_DEST}"
}

# ===============================================================================
# Parameters
# ===============================================================================
declare -i TEST=0
declare -a FILELIST
while getopts "f:ht" OPTION; do
    case ${OPTION} in
        h) usage
           exit 0
            ;;
        t) TEST=1
            ;;
        f) CONFIG_FILE="${OPTARG}"
            ;;
       \?) echo "Invalid option: -${OPTARG}" >&2
           exit 1
            ;;
    esac
done
    shift $(($OPTIND-1))

# ===============================================================================
# Main
# ===============================================================================
main() {
    FILELIST=( $(cat "${CONFIG_FILE:-"${PROGDIR}/link.conf"}") )
    if ((TEST==1)); then
        test_variables TEST PROGNAME PROGDIR FILELIST CONFIG_FILE; printf "\n"
    fi

    # If file is located within a subdirectory
    # the name of parent is stripped
    for FILE in "${FILELIST[@]}"; do
        if [ -f "${PROGDIR}/${FILE}" ]; then
            local LINK_SOURCE="${PROGDIR}/${FILE}"
            local LINK_DEST="${HOME}/.${FILE##*/}"

            if ((TEST==1)); then test_source && test_dest; continue; fi

            link_files >/dev/null 2>&1 || prompt_delete
        fi
    done
}

if [ "$0" = "${BASH_SOURCE}" ]; then
    main
fi
