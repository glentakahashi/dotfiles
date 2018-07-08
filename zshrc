source /etc/profile

# oh-my-zsh options
ZSH=~/.oh-my-zsh
ZSH_THEME="agnoster"
DISABLE_AUTO_UPDATE="true"
DISABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git)
source ~/.oh-my-zsh/oh-my-zsh.sh

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#vim is the best
EDITOR="vim"

# 10ms for key sequences
KEYTIMEOUT=1

#TODO: add git bindings
#aliases
alias reload-zshrc='source ~/.zshrc'
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

#yarn stuff
alias upgrade-yarn='curl -o- -L https://yarnpkg.com/install.sh | bash'
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

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

#fixes
#export TERM=screen-256color

#go stuff
export GOPATH=~/go
export PATH=$GOPATH/bin:$PATH

source ~/z.sh

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
