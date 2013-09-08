#[ENVAR]
export CLICOLOR=1
export LSCOLORS=Exfxcxdxbxegedabagacad
export GREP_OPTIONS='--color=auto'
export PATH=$PATH:$HOME/bin
export VIMRUNTIME=/usr/share/vim/vim73
export MARKPATH=$HOME/.marks

#[Prompt]
PS1='\[\033[36m\]Yes, Master?\[\033[m\] \[\e[0;33m\]Sang\[\e[0m\]:\[\033[36m\] ~$\[\033[m\] '

#[Aliases]

alias ls="ls -Fx"

alias Desktop="cd ~/Desktop"
alias Downloads="cd ~/Downloads"

alias sshPi="ssh shan@raspberrypi.local"
alias sshApps="ssh root@sangapps.com"
alias sshCloud="ssh root@sangcloud.com"
alias sshProxy="ssh -D 9999 -N root@sangcloud.com"

alias Inventory="open /Volumes/Optical\ Comp/Inventory/MEMS"
alias PinData="open /Volumes/PubStore/_Production\ Data/MEMs\ PROBE\ DATA/OSF"
alias Autoprober="open /Volumes/Public/Calient/AutoProber"
alias VLR1Log="open /Volumes/Optical\ Comp/Fab\ Folder/Tools/VLR1/VLR1\ Log.xls"
alias VLR2Log="open /Volumes/Optical\ Comp/Fab\ Folder/Tools/VLR2/VLR2\ Tool\ Log.xls"
alias FHTraveler="open /Volumes/Public/Calient/24\ OSF/Faceplate/Traveler"
alias HAN="open /Volumes/PubStore/_SB\ Employees/HAN"
alias PartialProbe="open /Volumes/Public/Calient/AutoProber/Data/Partial\ Probe"
alias QData="open /Volumes/Public/Calient/AutoProber/Data/Q\ measurement"
alias pin="pin_yieldv3.sh"
alias VisualComputer="open ~/Desktop/Calient/Visual.rdp"
alias AutoproberComputer="open ~/Desktop/Calient/Autoprober.rdp"
alias HoyounComputer="open ~/Desktop/Calient/Hoyoun.rdp"
alias SangComputer="open ~/Desktop/Calient/Sang.rdp"
alias JeremyComputer="open ~/Desktop/Calient/Jeremy.rdp"

alias m2u="tr '\015' '\012' "
alias u2m="tr '\012' '\015' "

#[Functions]

function ds () 	{
	echo "Disk Space Utilization for $HOSTNAME"
	df -h
}

function jump {
    cd -P "$MARKPATH/$1" 2> /dev/null || echo "No such mark: $1"
}

function mark {
    mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}

function unmark {
    rm -i "$MARKPATH/$1"
}

function marks {
    ls -l $MARKPATH | sed -e 's:\  : :g' -e 's:@::g' | cut -f 10- -d ' ' | sed -e 's:->:'$'\t''&:g'
}

_completemarks() {
    local curw=${COMP_WORDS[COMP_CWORD]}
    local wordlist=$(find ~/.marks -type l -print | rev | cut -f 1 -d '/' | rev)
    COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
    return 0
}

complete -F _completemarks jump unmark
