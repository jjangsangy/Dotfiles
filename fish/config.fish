function fish_greeting
  if type -q fastfetch
    fastfetch
  end
end

if type -q zoxide
  zoxide init fish --cmd cd | source
end

if not type -q fisher
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher && fisher update
  echo 'Installed Fish Plugins'
end

if type -q starship
  set -x STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"

  function starship_transient_prompt_func
    starship module character
  end
  function starship_transient_rprompt_func
    starship module time
  end

  starship init fish | source

  enable_transience
end

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/opt/google-cloud-sdk/path.fish.inc' ]; . '/usr/opt/google-cloud-sdk/path.fish.inc'; end

test -x $HOME/miniconda3/bin/conda
  and eval $HOME/miniconda3/bin/conda "shell.fish" "hook" $argv | source

