# Shell options (what oh-my-zsh's lib/ used to set, minus the parts I don't use)

# --- history ---------------------------------------------------------------
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=500000
SAVEHIST=500000
setopt extended_history        # save timestamps
setopt share_history           # share across sessions (implies inc_append_history)
setopt hist_expire_dups_first
setopt hist_ignore_dups        # don't record an immediate repeat
setopt hist_ignore_space       # ` cmd` (leading space) isn't saved
setopt hist_find_no_dups       # skip dups when searching
setopt hist_reduce_blanks
setopt hist_verify             # `!!` expands into the buffer instead of running

# Keep secrets and editor noise out of ~/.zsh_history.
# Returning 1 still lets the command run, it just isn't saved.
zshaddhistory() {
  local line=${1%%$'\n'}
  [[ $line =~ '(_KEY|_TOKEN|_SECRET|PASSWORD|PASSWD)=[^ ]' ]] && return 1
  [[ $line == *printEnvVariablesToFile.py* ]] && return 1   # cursor/vscode python ext
  return 0
}

# --- directories -----------------------------------------------------------
setopt auto_cd                 # `..` or `~/projects` alone cds
setopt auto_pushd pushd_ignore_dups pushd_minus
alias -- -='cd -'
alias ...='../..'
alias ....='../../..'
alias .....='../../../..'

# --- misc ------------------------------------------------------------------
setopt interactive_comments
setopt long_list_jobs
setopt no_flow_control         # free up ctrl-s / ctrl-q
setopt always_to_end complete_in_word

# url-quote-magic: auto-escape ? & etc. when pasting URLs
autoload -Uz url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic

# --- terminal / tmux title: dir when idle, command while running -------------
_title_precmd()  { print -Pn "\e]1;%15<..<%~%<<\a\e]2;%n@%m: %~\a" }
_title_preexec() {
  local cmd=${${1//\%/%%}//$'\n'/ }   # escape % for print -P, flatten newlines
  print -Pn "\e]1;${${cmd[(w)1]}[1,15]}\a\e]2;%n@%m: ${cmd[1,100]}\a"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd  _title_precmd
add-zsh-hook preexec _title_preexec
