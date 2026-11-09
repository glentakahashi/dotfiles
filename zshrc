#zmodload zsh/zprof   # uncomment (with `zprof` at the bottom) to profile startup
source /etc/profile

# kube-ps1
[[ -f ~/.kube-ps1/kube-ps1.sh ]] && source ~/.kube-ps1/kube-ps1.sh
export KUBE_PS1_NS_ENABLE=false
export KUBE_PS1_SYMBOL_ENABLE=false

# oh-my-zsh options
ZSH=~/.oh-my-zsh
ZSH_THEME="agnoster"
DISABLE_AUTO_UPDATE="true"
DISABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
ZSH_DISABLE_COMPFIX="true"          # skip the slow insecure-dir check on every start
plugins=(git)
source ~/.oh-my-zsh/oh-my-zsh.sh

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
# omz defaults SAVEHIST to 10000, which silently truncates the file.
HISTSIZE=500000
SAVEHIST=500000
setopt hist_reduce_blanks
setopt hist_find_no_dups

# Keep secrets and editor noise out of ~/.zsh_history.
# Returning 1 still lets the command run, it just isn't saved.
zshaddhistory() {
  local line=${1%%$'\n'}
  [[ $line =~ '(_KEY|_TOKEN|_SECRET|PASSWORD|PASSWD)=[^ ]' ]] && return 1
  [[ $line == *printEnvVariablesToFile.py* ]] && return 1   # cursor/vscode python ext
  return 0
}

# ---------------------------------------------------------------------------
# Vi mode / keys
# ---------------------------------------------------------------------------
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
autoload -Uz edit-command-line
zle -N edit-command-line

bindkey -v

# allow v to edit the command line (standard behaviour)
bindkey -M vicmd 'v' edit-command-line

# allow ctrl-p, ctrl-n for navigate history (standard behaviour)
bindkey '^P' up-history
bindkey '^N' down-history

# allow ctrl-h, ctrl-w, ctrl-? for char and word deletion (standard behaviour)
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word

# type a prefix then up/down to search history for it
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

#even for zsh
bindkey -M viins 'kj' vi-cmd-mode

# Units are 10ms. Long enough to type `kj` / ctrl-g chords, short enough that ESC
# doesn't lag (was 100 = 1s).
KEYTIMEOUT=30

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#vim is the best
export EDITOR="vim"
export VISUAL="vim"

# ---------------------------------------------------------------------------
# Aliases & helpers
# ---------------------------------------------------------------------------
alias reload-zshrc='exec zsh'
alias grip='grep -riI'
#simple http server
alias http='python3 -m http.server'
#most common commands - useful for determining what else i should alias to save time
alias mosthist="LC_ALL=C sed -E -n 's/^: [0-9]+:[0-9]+;//p' ~/.zsh_history | awk '{print \$1}' | sort | uniq -c | sort -rn | head -40"
alias mosthist2="LC_ALL=C sed -E -n 's/^: [0-9]+:[0-9]+;//p' ~/.zsh_history | awk '{print \$1, \$2}' | sort | uniq -c | sort -rn | head -40"
#recursive git status
alias rgs='find . -type d -name ".git" | while read dir ; do sh -c "cd $dir/../ && echo \"\nGIT STATUS IN ${dir//\.git/}\" && git status -s" ; done'
#so many typos
alias sl='ls'
alias gti='git'
alias gw='./gradlew'
alias darn='yarn --pure-lockfile'

# docker compose v2 (you type `docker compose ...` ~150x in history)
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcs='docker compose stop'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f --tail=200'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"'

alias python='python3'
alias pes='pipenv shell'

# omz in this fork predates git_main_branch; prefer origin/HEAD, then main, then master
(( $+functions[git_main_branch] )) || git_main_branch() {
  local ref=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  [[ -n $ref ]] && { echo ${ref#origin/}; return }
  git show-ref -q --verify refs/heads/main && echo main || echo master
}

# git: things you type a lot that omz doesn't cover (see `galias` for the rest)
alias gs='git status'
alias grim='git rebase -i origin/$(git_main_branch)'       # 36x `git rebase -i origin/master`
alias grom='git rebase origin/$(git_main_branch)'
alias gfm='git fetch origin $(git_main_branch)'
alias gup='git fetch origin $(git_main_branch) && git merge origin/$(git_main_branch)'  # 49x merge origin/master
alias gcm='git checkout $(git_main_branch)'
alias gundo='git reset --soft HEAD~1'
galias() { alias | grep -E '^g[a-z!]*=' | ${PAGER:-less} }

# claude
alias cl='claude'
alias clr='claude --resume'
alias clc='claude --continue'

# Formatting aliases
json() {
  if (( $+commands[jq] )); then jq . "${@:--}"; else python3 -m json.tool "${@:--}"; fi
}

weather() { curl "wttr.in/${1}" }
alias wthr='weather'

#yarn stuff
export PATH=$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH

#commonslyusedstuff
alias lsr='ls -lahtr'
alias dust='du -hs * | sort -h'

# ps | grep without matching the grep itself: `psg launch-kernel`
psg() { ps aux | grep -i -- "[${1[1]}]${1[2,-1]}" }

# what's listening on a port: `port 3000`
port() { lsof -nP -iTCP${1:+:$1} -sTCP:LISTEN }

# mkdir + cd
mkcd() { mkdir -p -- "$1" && cd -- "$1" }

#create a basic html file
html() {
  if [[ -z $1 ]]; then
    echo "Enter a path to create a basic html file at."
    return 1;
  fi
  cp ~/.template.html $1
}

# stash, update main, branch off it, unstash
gscb() {
  [[ -z $1 ]] && { echo "usage: gscb <new-branch>"; return 1 }
  local main=$(git_main_branch) stashed=0
  [[ -n $(git status --porcelain) ]] && git stash push -u -m "gscb $1" && stashed=1
  git checkout "$main" && git pull && git checkout -b "$1"
  (( stashed )) && git stash pop
}

# Cache the output of slow `eval "$(tool init)"` style commands.
# Regenerates when the tool binary changes. Use only for output that doesn't
# capture the current environment (e.g. NOT `devbox shellenv`).
#   cached_eval pyenv pyenv init - --no-rehash zsh
cached_eval() {
  local name=$1; shift
  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval-$name.zsh
  local bin=${commands[$1]}
  [[ -z $bin ]] && return 1
  if [[ ! -s $cache || $bin -nt $cache ]]; then
    mkdir -p ${cache:h}
    "$@" >| $cache 2>/dev/null
  fi
  source $cache
}

source ~/.z.sh

#fzf aliases
source ~/.zshrc.fzf

[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases

# load system specific overrides
source ~/.zshrc.system

# load local overrides
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# key bindings that must be (re)applied after `fzf --zsh` (defined in zshrc.fzf)
(( $+functions[fzf_post_init] )) && fzf_post_init

export AWS_PAGER=""
export PATH="$HOME/projects/hex/bin:$PATH"

# Created by `pipx` on 2025-03-04 01:09:25
export PATH="$PATH:$HOME/.local/bin"

[[ -d ${KREW_ROOT:-$HOME/.krew} ]] && export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# dedupe PATH (several files prepend the same dirs)
typeset -U path PATH
#zprof
