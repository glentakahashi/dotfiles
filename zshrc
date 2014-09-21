ADDONS=$HOME/.zsh

# oh-my-zsh options
ZSH=$ADDONS/oh-my-zsh
ZSH_THEME="agnoster"
DISABLE_AUTO_UPDATE="true"
DISABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git)
source $ZSH/oh-my-zsh.sh

#TODO: add git bindings
#aliases
alias reload-zshrc='source ~/.zshrc'
alias grip='grep -riI'
#simple http server
alias http='python -m SimpleHTTPServer'
#easycd
source $ADDONS/fs-easymotion/easycd.sh
alias u='easyCdUp'
#easyfind
source $ADDONS/fs-easymotion/easyfind.sh
alias f='easyFind'
alias ff='easyFindOpen'
#easygrep
source $ADDONS/fs-easymotion/easygrep.sh
alias g='easyGrep'
alias gg='easyGrepOpen'
#most common commands - useful for determining what else i should alias to save time
alias mosthist="cat ~/.zsh_history | sed -E -n 's/.*;([a-zA-Z0-9]*) .*/\1/p' | sort | uniq -c | awk '\$1 > 10' | sort -n"
alias mosthist2="cat ~/.zsh_history | sed -E -n 's/.*;([a-zA-Z0-9]* ?[a-zA-Z0-9]*) .*/\1/p' | sort | uniq -c | awk '\$1 > 10' | sort -n"

#fixes
export TERM=xterm-256color

#vimode!
bindkey -v

# load system specific overrides
source ~/.zshrc.system

# load local overrides
source ~/.zshrc.local
