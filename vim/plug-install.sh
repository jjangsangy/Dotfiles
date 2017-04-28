#!/usr/bin/env bash

set -euo pipefail


function success() {
    printf "\nDone! Run \":PlugInstall\" to Build Packages\n\n"
}

function echoerr() {
    printf "%s\n" "$*" >&2
}


function error() {
    echoerr "\n"
    echoerr "Installation unsuccessfull!"
    echoerr "Please make sure there are no leftover files"
    j
    for plug in ${HOME}/{'.local/share/nvim','.config/nvim','.vim/autoload/plug.vim'}; do
    {
        [ -f "${plug}" -o -d "${plug}" ] && rm -rf "${plug}"
    }
    done
}


trap error SIGHUP SIGINT SIGTERM


function install_plug() {
    local VIM_PLUG="${1}"
    local URL='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

    if [ ! -f "$VIM_PLUG" ]; then
    {
        printf "\nInstalling into Directory \n\t%s\n\n" "${VIM_PLUG%/*}"
        curl --remote-time --location --fail --create-dirs \
             --output "$VIM_PLUG" "$URL"
    }
    fi
}


function nvim_config() {
    local VIMRC="${1}"
    local INIT_VIM="${2}"

    # Ensure Directory Exists
    [ ! -d "${INIT_VIM%/*}" ] && mkdir -p "${INIT_VIM%/*}"

    # Symbolically Link vimrc for neovim
    if [ -f ${VIMRC} -a ! -h ${INIT_VIM} ]; then
    {
        printf "\nSymbolically Linking Neovim Vimrc\n"
        ln -s ${VIMRC} ${INIT_VIM} && ls --color=yes -l ${INIT_VIM}
    }
    fi
}


function main() {
    # Grab vim version banner
    local VIM_TYPE="$(vim --version | head -n1 | awk '{print $1}')"

    # Configuration for Vim vs Neovim are different
    if [ "$VIM_TYPE" = 'VIM' ]; then
        install_plug "${HOME}/.vim/autoload/plug.vim"
    elif [ "$VIM_TYPE" = 'NVIM' ]; then
        install_plug "${HOME}/.local/share/nvim/site/autoload/plug.vim"
        nvim_config "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"
    fi
}

if [ $0 = $BASH_SOURCE ]; then
    main && success
fi
