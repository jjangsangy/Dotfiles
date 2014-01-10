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
    for FILE in "${FILELIST[@]}"; do
        local LINK_SOURCE=${PROGDIR}/${FILE}
        local LINK_DEST=${HOME}/\.${FILE}
        link_files >/dev/null 2>&1 || prompt_delete
    done
}
