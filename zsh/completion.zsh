# Completion: compinit with a cached dump (full rebuild at most once a day),
# then fzf-tab for an fzf-powered completion menu.

fpath=(
  /opt/homebrew/share/zsh/site-functions
  $HOME/.local/share/devbox/global/default/.devbox/nix/profile/default/share/zsh/site-functions
  $fpath
)

autoload -Uz compinit
() {
  setopt local_options extended_glob
  local dump=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION
  mkdir -p ${dump:h}
  # (#qN.mh-24): dump exists and was modified within the last 24h -> skip checks
  if [[ -n $dump(#qN.mh-24) ]]; then
    compinit -C -d $dump
  else
    compinit -i -d $dump && touch $dump
  fi
  # compile in the background so the next start loads faster
  { [[ ! $dump.zwc -nt $dump ]] && zcompile $dump } &!
}

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=*'  # case-insensitive, substring
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:descriptions' format '[%d]'   # fzf-tab shows these as group headers
zstyle ':completion:*' menu no                     # let fzf-tab handle the menu
[[ -n $LS_COLORS ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# fzf-tab (must load after compinit, before plugins that wrap widgets)
if [[ -f $ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh ]]; then
  source $ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh
  zstyle ':fzf-tab:*' switch-group '<' '>'
  zstyle ':fzf-tab:*' fzf-flags --height=50%
  # match zshrc.fzf: tab completion in a tmux popup too
  [[ -n $TMUX && -z $FZF_NO_POPUP ]] && zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
  zstyle ':fzf-tab:complete:(cd|z|ls|vim|cat|bat):*' fzf-preview \
    '[[ -d $realpath ]] && ls -1 --color=always $realpath || head -100 $realpath'
  zstyle ':fzf-tab:complete:git-(checkout|switch|rebase|merge|log|diff):*' fzf-preview \
    'git log --oneline --graph --color=always -20 --end-of-options "$word" -- 2>/dev/null'
  zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,command'
fi
