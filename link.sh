#!/usr/bin/env bash
# ==============================================================================
function usage() { cat <<- DOCUMENT

    Usage: $PROGNAME [-h] [-t] [-c link.conf]

    AUTHOR:      Sang Han
    CREATED:     01/09/2014
    REVISION:    1.4

    DESCRIPTION:
        Program for automating users preferred login shell enviornment.
        Symbolically links the startup files located within dotfiles
        repository and links them to to users \$HOME variable prepended
        with a dot. If the startup file already and a collision occurs,
        user will be prompted for deletion.

    HOME DIRECTORY: $HOME

    REQUIREMENTS:
        - .conf (Config File)

    OPTIONS:
        -h [help]
            Outputs usage directions
        -t [test]
            A dry run, does not actually make changes to the filesystem
        -v [verbose]
            Prints out all test output to screen
        -c [config]
            Reference external configuration file as metadata
        -f [force]
            Always replace files: Warning this is dangerous

    EXAMPLES:
        Run unit tests and prints out all assigned values and variables
        ./${PROGNAME} -t

        Run program:
        ./$PROGNAME

        Use your own config file:
        ./$PROGNAME -c config_file

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
function test_variables() {
    declare -a variables=(${*})
    for var in "${variables[@]}"; do
        printf "%30s = %s\n" \
            "$(tput setaf 9)\$${var}$(tput sgr0)" \
            "$(tput setaf 3)${!var}$(tput sgr0)"
    done
}

function test_source() {
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

function test_dest() {
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

    if ((FORCE==1)); then
        rm -rf "${LINK_DEST}" 2>/dev/null
        link_files
        return
    fi

    read -p "File $LINK_DEST already exists, would you like to delete it? \
        [Yy]/[Nn]:  " RESPONSE

    if [[ $RESPONSE =~ [Yy] ]]; then
        rm "${LINK_DEST}" && link_files
    else
        return
    fi
}

# ===========================================================================
# Link Files
# ===========================================================================
function link_files() {
    ln -s "${LINK_SOURCE}" "${LINK_DEST}"
}

# ===============================================================================
# Parameters
# ===============================================================================
declare -i TEST=0 VERBOSE=0 FORCE=0
declare -a FILELIST
while getopts "c:htvf" OPTION; do
    case ${OPTION} in
        h) usage
           exit 0
            ;;
        t) TEST=1
            ;;
        c) CONFIG_FILE="${OPTARG}"
            ;;
        v) VERBOSE=1
            ;;
        f) FORCE=1
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
function main() {
    # Grab Config File
    FILELIST=( $(cat "${CONFIG_FILE:-"${PROGDIR}/link.conf"}") )

    if ((TEST==1 || VERBOSE==1)); then
        test_variables TEST PROGNAME PROGDIR FILELIST CONFIG_FILE FORCE
        printf "\n"
    fi

    # Parent directory name is stripped
    for FILE in "${FILELIST[@]}"; do
    {
        local LINK_SOURCE="${PROGDIR}/${FILE}"
        local LINK_DEST="${HOME}/.${FILE##*/}"

        test -d "${LINK_SOURCE}" && LINK_SOURCE="${LINK_SOURCE}"'/'

        if [ -e ${LINK_SOURCE} ]; then
        {
            # print out source and destination only
            if ((TEST==1)); then
                test_source && test_dest
                continue
            fi

            if ((VERBOSE==1)); then
                test_source && test_dest
            fi

            # Magic
            link_files >/dev/null 2>&1 || prompt_delete
        }
        fi
    }
    done
}

if [ "$0" = "${BASH_SOURCE}" ]; then
    main
fi
