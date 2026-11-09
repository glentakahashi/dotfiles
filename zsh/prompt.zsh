# Agnoster-style powerline prompt (ported from my oh-my-zsh fork).
# Needs a Powerline-patched font and looks right with the Solarized palette.
#
#   [✘⚙] [venv] [kube ctx] [AWS] user@host HH:MM:SS  ~/dir   branch ●✚ >R>
#    I                                       <- vi mode (I = insert, N = normal)
#
# Differences from the omz version, all for speed:
# - git info comes from one `git status --porcelain=v2` call instead of
#   vcs_info + parse_git_dirty (2-3 git calls), and only once per prompt:
#   switching vi modes no longer re-runs git.
# - dir truncation and the clock are pure zsh (no pwd/awk/tput/date forks).

setopt prompt_subst

CURRENT_BG='NONE'
case ${SOLARIZED_THEME:-dark} in
  light) CURRENT_FG='white';;
  *)     CURRENT_FG='black';;
esac
SEGMENT_SEPARATOR=$'\ue0b0'
PL_BRANCH_CHAR=$'\ue0a0'

# prompt_segment <bg> <fg> [text]
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    print -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -nr -- "$3"
}

prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

# error / root / background jobs
prompt_status() {
  local -a symbols
  (( _prompt_retval != 0 )) && symbols+="%{%F{red}%}✘"
  (( UID == 0 ))            && symbols+="%{%F{yellow}%}⚡"
  (( ${#jobstates} ))       && symbols+="%{%F{cyan}%}⚙"
  [[ -n $symbols ]] && prompt_segment black default "${(j::)symbols}"
}

prompt_virtualenv() {
  [[ -n $VIRTUAL_ENV && -n $VIRTUAL_ENV_DISABLE_PROMPT ]] && prompt_segment blue black "(${VIRTUAL_ENV:t})"
}

# current kube context, read straight from the kubeconfig file(s) and cached
# until their mtime changes (replaces kube-ps1; `kubectl config` costs ~50ms)
zmodload -F zsh/stat b:zstat 2>/dev/null
_prompt_kube_update() {
  local -a files=(${(s.:.)${KUBECONFIG:-$HOME/.kube/config}}) st
  local f key= line
  for f in $files; do
    [[ -r $f ]] && zstat -A st +mtime -- $f 2>/dev/null && key+="$f@$st[1];"
  done
  [[ $key == $_prompt_kube_key ]] && return
  _prompt_kube_key=$key _prompt_kube_ctx=
  for f in $files; do
    [[ -r $f ]] || continue
    line=${${(M)${(f)"$(<$f)"}:#current-context:*}[1]}
    line=${${line#current-context:}//[\"\' ]/}
    [[ -n $line ]] && { _prompt_kube_ctx=${line##*/}; return }
  done
}

# kube context; red if it looks like prod
prompt_kubectl() {
  local ctx=$_prompt_kube_ctx
  [[ -z $ctx ]] && return
  case $ctx in
    *-prod*|*production*) prompt_segment red yellow "$ctx" ;;
    *)                    prompt_segment green black "$ctx" ;;
  esac
}

prompt_aws() {
  [[ -z $AWS_PROFILE ]] && return
  case $AWS_PROFILE in
    *-prod|*production*) prompt_segment red yellow "AWS: $AWS_PROFILE" ;;
    *)                   prompt_segment green black "AWS: $AWS_PROFILE" ;;
  esac
}

prompt_context() {
  if [[ $USER != $DEFAULT_USER || -n $SSH_CLIENT ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%n@%m %*"
  fi
}

# Keep the first two path components and as many trailing ones as fit in
# half the terminal width: ~/projects/…/packages/server
prompt_dir() {
  local p=${(%):-%~} max=$(( COLUMNS / 2 ))
  local -a parts=("${(@s:/:)p}")
  if (( ${#p} > max && ${#parts} > 3 )); then
    local head="${parts[1]}/${parts[2]}/…/" tail=${parts[-1]} i
    for (( i = ${#parts} - 1; i > 3; i-- )); do
      (( ${#head} + ${#parts[i]} + ${#tail} + 1 > max )) && break
      tail="${parts[i]}/$tail"
    done
    p=$head$tail
  fi
  prompt_segment blue $CURRENT_FG "${p//\%/%%}"
}

prompt_git() {
  (( $+commands[git] )) || return
  local line head oid staged= unstaged= mode= gitdir
  local -a out
  local untracked=normal
  [[ $DISABLE_UNTRACKED_FILES_DIRTY == true ]] && untracked=no
  out=("${(@f)$(git status --porcelain=v2 --branch --untracked-files=$untracked 2>/dev/null)}") || return
  [[ -z ${out[1]} ]] && return
  for line in $out; do
    case $line in
      '# branch.head '*) head=${line#\# branch.head } ;;
      '# branch.oid '*)  oid=${line#\# branch.oid } ;;
      [12]' '*)
        [[ ${line[3]} != . ]] && staged='✚'
        [[ ${line[4]} != . ]] && unstaged='●' ;;
      [u?]' '*) unstaged='●' ;;
    esac
  done
  if [[ -n $staged$unstaged ]]; then
    prompt_segment yellow black
  else
    prompt_segment green $CURRENT_FG
  fi
  gitdir=$(git rev-parse --git-dir 2>/dev/null)
  if   [[ -e $gitdir/BISECT_LOG ]]; then mode=" <B>"
  elif [[ -e $gitdir/MERGE_HEAD ]]; then mode=" >M<"
  elif [[ -e $gitdir/rebase-merge || -e $gitdir/rebase-apply ]]; then mode=" >R>"
  fi
  if [[ $head == '(detached)' ]]; then
    head="➦ ${oid[1,7]}"
  else
    head="$PL_BRANCH_CHAR $head"
  fi
  local flags=$unstaged$staged
  print -nr -- "${head//\%/%%}${flags:+ $flags}$mode"
}

_prompt_build_top() {
  CURRENT_BG='NONE'
  prompt_status
  prompt_virtualenv
  prompt_kubectl
  prompt_aws
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

_prompt_build_mode() {
  CURRENT_BG='NONE'
  if [[ $KEYMAP == vicmd ]]; then
    prompt_segment green black " N "
  else
    prompt_segment white blue " I "
  fi
  prompt_end
}

# Two hooks: save $? before any other precmd hook (direnv etc.) clobbers it,
# and build the prompt after the others (direnv may change the environment).
# Order is enforced by prompt_fix_hook_order, called at the end of zshrc.
_prompt_save_status() { _prompt_retval=$? }
_prompt_precmd()      { _prompt_kube_update; _prompt_top=$(_prompt_build_top) }
prompt_fix_hook_order() {
  precmd_functions=(_prompt_save_status
    ${precmd_functions:#(_prompt_save_status|_prompt_precmd)} _prompt_precmd)
}
prompt_fix_hook_order

PROMPT='%{%f%b%k%}${_prompt_top}
$(_prompt_build_mode) '
