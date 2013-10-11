#!/usr/bin/env bash

if ! [[ -d $HOME/bin ]]; then
	mkdir $HOME/bin
fi
# made a random comment

if [[ $(uname -s) == "Linux" ]]; then
    APTPREINSTALL=(git git-core vim zsh curl wget)
    clear
    echo "Please Select:

    1. Update & Install?
    2. Only Install?
    0. Quit
    "
    read -p "Enter selection [1-3]: " RESP
    case ${RESP} in
        1)  echo "Updating System"
            sudo apt-get update && sudo apt-get upgrade && echo "System is now up to date"
        echo "Now installing ${APTPREINSTALL[*]}" && sudo apt-get install ${APTPREINSTALL[*]}
        ;;
        2)  echo "Now installing ${APTPREINSTALL[*]}" && sudo apt-get install ${APTPREINSTALL[*]}
        ;;
        0)  echo "Exiting"
        exit
        ;;
        *)  echo "Sorry does not match any selections"

        esac
fi

if [[ $(uname -s) == "Darwin" ]]; then
        which -s brew
        if [[ $? != 0 ]]; then
                BREWINSTALL=(curl git ctags wget zsh vim tmux python)
                echo "Installing Homebrew..."
                ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
                brew update
                    for apps in "${BREWINSTALL[@]}"; do
                    brew install ${apps}
                    done
        fi

        if ! [[ -d "$HOME/Dotfiles" ]]; then
            git clone https://github.com/jjangsangy/Dotfiles.git "$HOME/Dotfiles"
        fi

        source $HOME/Dotfiles/osx/osx.sh

        if ! [[ -d ${HOME}/bin/maximum-awesome ]]; then
                echo "Installing Maximum Awesome VIM"
                maxDIR="${HOME}/bin/maximum-awesome"
                dotDIR="${HOME}/Dotfiles"
                myVIMRC=("${dotDIR}/vim/vimrc" "${dotDIR}/vim/vimrc.local")
                git clone https://github.com/square/maximum-awesome.git "${maxDIR}" && cd "${maxDIR}" && rake

                for file in "${myVIMRC[@]}"; do
                origFile="${HOME}/.${file##*/}"
                    if [[ -f "${file}" ]]; then
                          if [[ -f "${origFile}" ]]; then
                                rm "${origFile}"
                          fi
                          ln "${file}" "${origFile}"
                    fi
                done
        fi

fi
