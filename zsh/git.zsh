# Git aliases. Names follow oh-my-zsh's git plugin so cheat sheets still apply,
# but only the ones worth knowing. `galias` prints this list.
# zsh-you-should-use reminds you when you type the long form.

# origin/HEAD -> main/master detection (cached per repo for the session)
git_main_branch() {
  local ref
  ref=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null) && { print ${ref#origin/}; return }
  git show-ref -q --verify refs/heads/main && print main || print master
}
git_current_branch() { git branch --show-current 2>/dev/null }

alias g='git'
alias gti='git'

## status / add                         (history: status 735x, add -p 290x, add . 318x)
alias gst='git status'
alias gss='git status -s'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'

## commit                               (commit -m 581x)
alias gc='git commit -v'
alias gcmsg='git commit -m'
alias 'gc!'='git commit -v --amend'
alias 'gcn!'='git commit --amend --no-edit'
alias gundo='git reset --soft HEAD~1'          # uncommit, keep changes staged

## diff / show / log                    (diff 354x)
alias gd='git diff'
alias gds='git diff --staged'
alias gdom='git diff origin/$(git_main_branch)'
alias gsh='git show'
alias glog='git log --oneline --decorate --graph -30'

## branches                             (checkout 348x, checkout -b 104x)
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout $(git_main_branch)'
alias gbr='git recent'                         # branches by last commit (gitconfig alias)

## push / pull                          (push 544x, pull 245x, push --force 56x)
alias gp='git push'
alias gpf='git push --force-with-lease'        # safe force: fails if remote moved
alias 'gpf!'='git push --force'
alias gl='git pull'
alias gf='git fetch'

## rebase / merge                       (rebase -i origin/master 36x, merge origin/master 49x)
alias grb='git rebase'
alias grbi='git rebase -i'
alias grim='git rebase -i origin/$(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias gm='git merge'
alias gmom='git merge origin/$(git_main_branch)'
alias gup='git fetch origin $(git_main_branch) && git merge origin/$(git_main_branch)'

## reset / stash                        (stash 123x, reset 75x)
alias grh='git reset'
alias grhh='git reset --hard'
alias gsta='git stash push'
alias gstu='git stash push -u'
alias gstp='git stash pop'
alias gstl='git stash list'

galias() {
  print -P "%BGit aliases%b  (also fzf: fco fcoa fga fgap fgd fstash fshow fpr; ctrl-g ctrl-b/h/f/s/t inserts)"
  awk '
    /^## / { sub(/^## /, ""); printf "\n\033[1;34m%s\033[0m\n", $0; next }
    /^alias / {
      line = substr($0, 7); n = index(line, "=")
      name = substr(line, 1, n - 1); val = substr(line, n + 1); note = ""
      if (match(val, /  +#.*/)) { note = substr(val, RSTART); val = substr(val, 1, RSTART - 1) }
      gsub(/^'\''|'\''$/, "", name); gsub(/^'\''|'\''$/, "", val)
      printf "  \033[32m%-6s\033[0m %s\033[2m%s\033[0m\n", name, val, note
    }' ${DOTFILES:-~/projects/dotfiles}/zsh/git.zsh
}

# stash, update main, branch off it, unstash
gscb() {
  [[ -z $1 ]] && { echo "usage: gscb <new-branch>"; return 1 }
  local main=$(git_main_branch) stashed=0
  [[ -n $(git status --porcelain) ]] && git stash push -u -m "gscb $1" && stashed=1
  git checkout "$main" && git pull && git checkout -b "$1"
  (( stashed )) && git stash pop
}
