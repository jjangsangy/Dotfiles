#!/bin/bash
# FILE:         Jump
# AUTHOR:       Sang Han
# VERSION:      1.1.0
# DESCRIPTION:  Automated tool for quickly traversing the shell in
#               unix based filesystems.

# Defines user directory for storing symlinks
export MARKPATH=$HOME/.marks
if ! [[ -d "$MARKPATH" ]]; then
    printf "No directory at %s\nDirectory being created\n" "${MARKPATH}"
    mkdir -p "$MARKPATH"
fi

usage() {

    PROGNAME=$(basename "${BASH_SOURCE}")
    PROGDIR=$(dirname "${BASH_SOURCE}")

    cat <<- EOF
    $PROGNAME [-h help] [-s silent]

    Automated tool for quickly traversing the shell in
    unix based filesystems.

    File is meant to be sourced from .bashrc or .profile
    at the start of a session. Executing this file directly
    will automatically source itself by writing to .bashrc
    or .profile

    AUTHOR:     Sang Han
    YEAR:       2013
    VERSION:    1.1.0

    -h [help]
        Outputs usage directions
    -t [test]
        Runs internal unit tests
    -i [install]
        Perform installation

EOF
    exit 0
}

jump() {
    cd -P "$MARKPATH/$1" 2> /dev/null || echo "No such mark: $1"
}

mark() {
    local MARKING="$MARKPATH/$1"
    ln -s "$(pwd)" "$MARKING" || \
        printf "Could not symlink %s to %s" "$(pwd)" "$MARKING"
}

unmark() {
    rm -i "$MARKPATH/$1"
}

marks() {
    ls -l $MARKPATH | sed -e 's:\  : :g' -e 's:@::g' | cut -f 9- -d ' ' | \
    awk \
        'BEGIN {FS="->"}; NR>1 {printf("%-3.2d %-24s %s %s\n",NR-1,$1,"->",$2)}'
}

_completemarks() {
    local curw=${COMP_WORDS[COMP_CWORD]}
    local wordlist=$(find ~/.marks -type l -print | rev | cut -f 1 -d '/' | rev)
    COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
    return 0
}

complete -F _completemarks jump unmark

if [ $0 = $BASH_SOURCE ]; then
    # Internal script functions and logic

    # Parse Options
    declare -i TEST=0 INSTALL=0
    while getopts ":ht" OPTION; do
        case ${OPTION} in
            h) usage
                ;;
            t) TEST=1
                ;;
            i) INSTALL=1
                ;;
            \?) echo "Invalid option: -${OPTARG}" >&2
                exit 1
                ;;
        esac
    done
        shift $(($OPTIND-1))

    install_jump() {
    # Automated install script
        cat <<- JUMP >> $HOME/.jump.sh
            export MARKPATH=$HOME/.mark
            $(declare -f {mark,unmark,_completemarks,jump})
JUMP

        cat <<- JUMP_SOURCE >> $HOME/.profile
            [ -f $HOME/.jump.sh ]; then
                source $HOME/.jump.sh
            fi
JUMP_SOURCE
    }

    # If ran with -i flag, run install script
    if [ $INSTALL = 1 ]; then
        install_jump
    fi

fi



