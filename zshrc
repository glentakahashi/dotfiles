#zmodload zsh/zprof
source /etc/profile
source ~/.kube-ps1/kube-ps1.sh

# oh-my-zsh options
ZSH=~/.oh-my-zsh
ZSH_THEME="agnoster"
DISABLE_AUTO_UPDATE="true"
DISABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git)
source ~/.oh-my-zsh/oh-my-zsh.sh

# Updates editor information when the keymap changes.
function zle-keymap-select() {
  zle reset-prompt
  zle -R
}

# Ensure that the prompt is redrawn when the terminal size changes.
TRAPWINCH() {
  zle && { zle reset-prompt; zle -R }
}

zle -N zle-keymap-select
zle -N edit-command-line


bindkey -v

# allow v to edit the command line (standard behaviour)
autoload -Uz edit-command-line
bindkey -M vicmd 'v' edit-command-line

# allow ctrl-p, ctrl-n for navigate history (standard behaviour)
bindkey '^P' up-history
bindkey '^N' down-history

# allow ctrl-h, ctrl-w, ctrl-? for char and word deletion (standard behaviour)
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word

#even for zsh
bindkey -M viins 'kj' vi-cmd-mode

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE="utf-8"

#vim is the best
EDITOR="vim"

# 10ms for key sequences
KEYTIMEOUT=100

#TODO: add git bindings
#aliases
alias reload-zshrc='exec zsh'
alias grip='grep -riI'
#simple http server
alias http='python -m SimpleHTTPServer'
#most common commands - useful for determining what else i should alias to save time
alias mosthist="cat ~/.zsh_history | sed -E -n 's/.*;([^ ]*)( ?.*)/\1/p' | sort | uniq -c | awk '\$1 > 10' | sort -n"
alias mosthist2="cat ~/.zsh_history | sed -E -n 's/.*;([^ ]* ?[^ ]*)( ?.*)/\1/p' | sort | uniq -c | awk '\$1 > 10' | sort -n"
#recursive git status
alias rgs='find . -type d -name ".git" | while read dir ; do sh -c "cd $dir/../ && echo \"\nGIT STATUS IN ${dir//\.git/}\" && git status -s" ; done'
#so many typos
alias sl='ls'
alias gw='./gradlew'
alias darn='yarn --pure-lockfile'
alias upgrade-yarn='curl -o- -L https://yarnpkg.com/install.sh | bash'

alias dcs='docker-compose stop'
alias dcu='docker-compose up -d'
alias dcr='docker-compose restart'
alias dcl='docker-compose logs -f'

# Formatting aliases
json() {
  cat $1 | python -m json.tool
}

alias pes='pipenv shell'

weather() {
  if [[ -z $1 ]]; then
    curl wttr.in
  else
    curl wttr.in/$1
  fi
}

alias wthr='weather'

#yarn stuff
export PATH=$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH

#commonslyusedstuff
alias lsr='ls -lahtr'
alias dust='du -hs * | sort -h'

#create a basic html file
html() {
  if [[ -z $1 ]]; then
    echo "Enter a path to create a basic html file at."
    return 1;
  fi
  cp ~/.template.html $1
}

gscb() {
  git stash && git checkout master && git pull && git checkout -b $1 && git stash pop
}

#fixes
#export TERM=xterm-256color

if [[ ! -z $ELECTRON_RUN_AS_NODE ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
else
    if [ -s "$HOME/.nvm/nvm.sh" ] && [ ! "$(type -f __init_nvm)" = function ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        declare -a __node_commands=(nvm yarn `find -L $NVM_DIR/versions/*/*/bin -type f -exec basename {} \; | sort -u`)
        function __init_nvm() {
            for i in "${__node_commands[@]}"; do unalias $i; done
            . "$NVM_DIR"/nvm.sh
            unset __node_commands
            unset -f __init_nvm
        }
        for i in "${__node_commands[@]}"; do alias $i='__init_nvm && '$i; done
    fi
fi

source ~/.z.sh

#fzf aliases
source ~/.zshrc.fzf

# load system specific overrides
source ~/.zshrc.system

# load local overrides
source ~/.zshrc.local

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

zle     -N   fzf-history-widget
bindkey '\er' fzf-history-widget

zle     -N   fzf-file-widget
bindkey '\et' fzf-file-widget

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
#zprof

# krew path
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
