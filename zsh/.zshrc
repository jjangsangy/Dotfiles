ZSH=$HOME/.oh-my-zsh
ZSH_THEME="ys"
source $ZSH/oh-my-zsh.sh

plugins=(git osx)

export MARKPATH=$HOME/.marks
export PATH=$HOME/bin:/anaconda/bin:$PATH

## OS X Matlab Console
if [[ -f /Applications/MATLAB_R2013a.app/bin/matlab ]]; then
    export PATH=$PATH:/Applications/MATLAB_R2013a.app/bin
    alias matlab="matlab -nojvm -nosplash"
fi

#[Aliases]
alias myPATH="echo $PATH | tr ':' '\n' | sort"

alias Desktop="cd ~/Desktop"
alias Downloads="cd ~/Downloads"

alias sshPi="ssh sang@raspberrypi.calient.local"
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

function git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

function get_pwd() {
  print -D $PWD
}

function battery_charge() {
  if [ -e ~/bin/batcharge.py ]
  then
    echo `python ~/bin/batcharge.py`
  else
    echo ''
  fi
}

function put_spacing() {
  local git=$(git_prompt_info)
  if [ ${#git} != 0 ]; then
    ((git=${#git} - 10))
  else
    git=0
  fi

  local bat=$(battery_charge)
  if [ ${#bat} != 0 ]; then
    ((bat = ${#bat} - 18))
  else
    bat=0
  fi

  local termwidth
  (( termwidth = ${COLUMNS} - 3 - ${#HOST} - ${#$(get_pwd)} - ${bat} - ${git} ))

  local spacing=""
  for i in {1..$termwidth}; do
    spacing="${spacing} " 
  done
  echo $spacing
}

source $ZSH/lib/git.zsh

function precmd() {
print -rP '
$fg[cyan]%m: $fg[yellow]$(get_pwd)$(put_spacing)$(git_prompt_info) $(battery_charge)'
}

PROMPT='%{$reset_color%}→ '

ZSH_THEME_GIT_PROMPT_PREFIX="[git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="]$reset_color"
ZSH_THEME_GIT_PROMPT_DIRTY="$fg[red]+"
ZSH_THEME_GIT_PROMPT_CLEAN="$fg[green]"
