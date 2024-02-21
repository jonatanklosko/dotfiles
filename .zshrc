# Initialize zsh

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# Plugins sourced from $ZSH/plugins/ and $ZSH_CUSTOM/plugins/
FZF_BASE="/opt/homebrew/opt/fzf"
plugins=(git fzf docker)

source "$ZSH/oh-my-zsh.sh"

# Aliases

# For more details see https://www.atlassian.com/git/tutorials/dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

alias o="open"
alias e="zed"
alias d="docker"
alias dc="docker-compose"
alias l="eza --long --group-directories-first"
alias la="eza --long --group-directories-first --all"
alias ls="eza --group-directories-first"
alias cat="bat"

alias gs="echo '🙈'"
alias gdm="git diff main"
alias gdms="git diff main --stat"
alias gd1="git diff HEAD~1"

alias mf="mix format"
alias mfa="mix format.all"
alias mt="mix test"
alias mtw="fswatch lib test | mix test --stale --listen-on-stdin"
alias md="mix docs -f html"
alias mr="mix run"
alias mc="mix compile"

alias lb="LIVEBOOK_DATA_PATH=$HOME/stuff/notebooks/.livebook LIVEBOOK_HOME=$HOME/stuff/notebooks livebook server @home"

# Environment setup

export LANG=en_US.UTF-8
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/bin:$PATH"

. "$(brew --prefix asdf)/libexec/asdf.sh"

eval "$(starship init zsh)"

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Set the torch installation directory for torchx
export LIBTORCH_DIR="/opt/homebrew/Cellar/pytorch/1.13.0"

# Persist IEx history across sessions
export ERL_AFLAGS="-kernel shell_history enabled"
