#zmodload zsh/zprof   # uncomment (with `zprof` at the bottom) to profile startup

# real location of this repo (~/.zshrc is a symlink into it)
DOTFILES=${${(%):-%x}:A:h}
# zsh plugins are cloned here by deploy.sh
ZSH_PLUGINS=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins

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

export EDITOR="vim"
export VISUAL="vim"
export AWS_PAGER=""
export RIPGREP_CONFIG_PATH=$HOME/.config/ripgrep/config   # -> $DOTFILES/ripgreprc
DISABLE_UNTRACKED_FILES_DIRTY=true   # prompt: untracked files don't mark the repo dirty

# system specific locale, PATH, colors, aliases (darwin/ or linux-gnu/)
source ~/.zshrc.system

source $DOTFILES/zsh/options.zsh
source $DOTFILES/zsh/completion.zsh

# ---------------------------------------------------------------------------
# Vi mode / keys
# ---------------------------------------------------------------------------
bindkey -v

# redraw prompt (vi mode indicator) on keymap change and terminal resize
zle-keymap-select() { zle reset-prompt; zle -R }
zle -N zle-keymap-select
TRAPWINCH() { zle && { zle reset-prompt; zle -R } }

# v in normal mode edits the command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line '^[[F' end-of-line

# type a prefix then up/down (or k/j in normal mode) to search history for it
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

bindkey -M viins 'kj' vi-cmd-mode

# How long zsh waits for the next key of a multi-key binding (`kj`, ctrl-g
# ctrl-b, ...) and after ESC. Units of 10ms: 30 = 300ms.
KEYTIMEOUT=30

# ---------------------------------------------------------------------------
# Aliases & helpers
# ---------------------------------------------------------------------------
source $DOTFILES/zsh/git.zsh

# Replace this process with a fresh login zsh: empty env, base PATH, full startup.
# Plain `exec zsh` inherits the old PATH, so direnv/devbox entries end up behind homebrew.
reload-zshrc() {
  local -a keep=(HOME USER LOGNAME SHELL PWD TERM COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION
                 LANG LC_ALL TMPDIR SSH_AUTH_SOCK SSH_CONNECTION SSH_TTY TMUX TMUX_PANE)
  local -a envs=() v
  for v in $keep; do [[ -n ${(P)v} ]] && envs+=("$v=${(P)v}"); done
  exec env -i "${envs[@]}" PATH=/usr/bin:/bin:/usr/sbin:/sbin "$SHELL" -l
}
alias grip='grep -riI'
alias http='python3 -m http.server'
# most common commands - useful for deciding what else to alias
alias mosthist="LC_ALL=C sed -E -n 's/^: [0-9]+:[0-9]+;//p' ~/.zsh_history | awk '{print \$1}' | sort | uniq -c | sort -rn | head -40"
alias mosthist2="LC_ALL=C sed -E -n 's/^: [0-9]+:[0-9]+;//p' ~/.zsh_history | awk '{print \$1, \$2}' | sort | uniq -c | sort -rn | head -40"
# recursive git status
alias rgs='find . -type d -name ".git" | while read dir ; do sh -c "cd $dir/../ && echo \"\nGIT STATUS IN ${dir//\.git/}\" && git status -s" ; done'
alias sl='ls'
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
alias lsr='ls -lahtr'
alias dust='du -hs * | sort -h'
alias gw='./gradlew'
alias python='python3'

# docker compose v2
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcs='docker compose stop'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f --tail=200'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"'

# hex dev server (from `coach`: typed ~350x)
alias hw='hdev watch'
alias hwl='hdev watch:local'
alias hi='hdev install'
alias hpi='hdev poetry install'
alias rd='./scripts/run-dev.sh'

# claude
alias cl='claude'
alias clr='claude --resume'
alias clc='claude --continue'

json() {
  if (( $+commands[jq] )); then jq . "${@:--}"; else python3 -m json.tool "${@:--}"; fi
}
# ps | grep without matching the grep itself: `psg launch-kernel`
psg() { ps aux | grep -i -- "[${1[1]}]${1[2,-1]}" }
# what's listening on a port: `port 3000` (or all with no arg)
port() { lsof -nP -iTCP${1:+:$1} -sTCP:LISTEN }
mkcd() { mkdir -p -- "$1" && cd -- "$1" }


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------
source $DOTFILES/zsh/prompt.zsh

# fzf: brew's fzf, falling back to the old ~/.fzf git checkout
source ~/.zshrc.fzf
cached_eval fzf fzf --zsh
(( $+commands[fzf] && ! $+widgets[fzf-history-widget] )) &&
  print -u2 "zshrc: fzf $(fzf --version 2>/dev/null | cut -d' ' -f1) is too old for its key bindings (needs 0.48+); run $DOTFILES/deploy.sh"
fzf_post_init

# zoxide (`z foo`, `zi` / `j` to pick)
if (( $+commands[zoxide] )); then
  cached_eval zoxide zoxide init zsh
  unfunction j 2>/dev/null; alias j='zi'
fi

source $DOTFILES/zsh/kubectl_aliases.zsh   # vendored ahmetb/kubectl-aliases

# machine-local overrides (not in the repo)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

source $DOTFILES/zsh/coach.zsh   # `coach`: shortcut suggestions from your history

[[ -d ~/projects/hex/bin ]] && path=(~/projects/hex/bin $path)
path+=(~/.local/bin)                   # uv tools, claude, copy (Linux puts it first)
[[ -d ${KREW_ROOT:-$HOME/.krew} ]] && export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
typeset -U path PATH                   # dedupe

# ---------------------------------------------------------------------------
# Plugins that wrap zle widgets: load last, syntax highlighting very last
# ---------------------------------------------------------------------------
if [[ -f $ZSH_PLUGINS/zsh-you-should-use/you-should-use.plugin.zsh ]]; then
  YSU_MESSAGE_POSITION=after
  YSU_IGNORED_ALIASES=(g gti sl l la ll python)
  source $ZSH_PLUGINS/zsh-you-should-use/you-should-use.plugin.zsh
  add-zsh-hook -D preexec _check_git_aliases   # shell aliases are enough; skip `git st` hints
fi
if [[ -f $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200
  ZSH_AUTOSUGGEST_MANUAL_REBIND=1      # faster; widgets are bound once
  source $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
  bindkey '^ ' autosuggest-accept      # ctrl-space accepts (right-arrow / ctrl-e also work)
fi
[[ -f $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# direnv last: it snapshots the environment when it loads a .envrc, so PATH
# entries added after the hook (e.g. ~/.local/bin, where claude lives) went
# missing inside direnv'd repos like hex.
(( $+commands[direnv] )) && cached_eval direnv direnv hook zsh

prompt_fix_hook_order   # direnv etc. registered hooks after the prompt did

#zprof

