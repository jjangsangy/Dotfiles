if [[ -d /anaconda ]]; then
    export PATH=/anaconda/bin:$PATH
fi

if [[ -f /Applications/MATLAB_R2013a.app/bin/matlab ]]; then
    export PATH=$PATH:/Applications/MATLAB_R2013a.app/bin
    alias matlab="matlab -nojvm -nosplash"
fi

if [[ -d $HOME/bin ]]; then
    export PATH=$HOME/bin:$PATH
fi

which brew -s > /dev/null
if [[ $? == 0 ]]; then
    export PATH=/usr/local/bin:$PATH
fi
