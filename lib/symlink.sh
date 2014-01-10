#!/bin/bash
#===============================================================================
#
#          FILE: link_files.sh
#
#   DESCRIPTION: function library for linking files to home directory
#
#        AUTHOR: Sang Han, shan@calient.net
#       CREATED: 01/09/2014
#      REVISION: 1.0.0
#===============================================================================

test_local() {
    printf "\$LINK_SOURCE and \$LINK_DEST is \
        \n%s\n%s\n\n" "${LINK_SOURCE}" "${LINK_DEST}"
}

test_param(){
    printf "\$FILELIST has %d files\n" "${#FILELIST[@]}"
    printf "\$FILELIST is %s\n" "${FILELIST[*]}"
}

link_files() {
    ln -s "${LINK_SOURCE}" "${LINK_DEST}"
}

prompt_delete() {
    read -p "File $LINK_DEST already exists\n \
        would you like to delete it?\n \
        [Yy]/[Nn]:  " RESPONSE

    if [[ $RESPONSE =~ [Yy] ]]; then
        rm "${LINK_DEST}"
        link_files
    else
        return
    fi

}

link() {
    declare -a FILELIST=("$@")
        ((TEST==1)) && test_param

    for FILE in "${FILELIST[@]}"; do
        local LINK_SOURCE=${PROGDIR:="${HOME}/Dotfiles"}/${FILE}
        local LINK_DEST=${HOME}/\.${FILE}
            ((TEST==1)) && { test_local; continue; }

        link_files >/dev/null 2>&1 || prompt_delete
    done
}

