#!/usr/bin/env bash

git remote set-url origin https://github.com/jjangsangy/Dotfiles.git

if ! [[ -d $HOME/bin ]]; then
	mkdir $HOME/bin
fi

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
                BREWINSTALL=(curl git valgrind ctags wget vim tmux "python --framework")
                echo "Installing Homebrew..."
                ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
                brew update
                brew install ${BREWINSTALL[*]}
        fi

fi

