#!/usr/bin/env bash
usage () { cat <<- DOCUMENT
#===============================================================================
#
#          FILE: brew-max.sh
#
#         USAGE: ./brew-max.sh formula
#
#   DESCRIPTION: Installs all of the --with-* formulas available to brew,
#                plus any additional space delimited flags.
#
#  REQUIREMENTS: brew
#       OPTIONS: -h (Print Usage)
#        AUTHOR: Sang Han (jjangsangy@gmail.com)
#       CREATED: 09/07/2015
#      REVISION: 1.0.0
#===============================================================================
DOCUMENT

    return 0
}

function main() {
    local formula="$1" && shift && local array=($@)
    local options="$(brew info "${formula}" | grep '^\-\-with-')"

    printf "Installing with these options \n%s\n" "${options}"

    brew install "${formula}" "${array[@]}" "${options}"
}


# ===============================================================================
# Option Parser
# ===============================================================================
while getopts ":liha" OPTION; do
    case ${OPTION} in
        h) usage
           exit 0
           ;;
       \?) echo "Invalid option: -${OPTARG}" >&2
           usage
           exit 1
           ;;
    esac
done
    shift $((OPTIND-1))

unset HOMEBREW_VERBOSE

# ===============================================================================
if [ "$0" = "${BASH_SOURCE}" ]; then
    main "$@"
fi
