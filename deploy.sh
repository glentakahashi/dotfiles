#!/usr/bin/env bash
# Install / update everything. Idempotent: safe to re-run any time.
#
#   ./deploy.sh              everything
#   ./deploy.sh --no-brew    skip brew bundle (packages)
#   ./deploy.sh --no-vim     skip vim-plug install/update
#   ./deploy.sh --update     also bump pinned third-party code (plugins.lock,
#                            vendored files, vim plugins) to latest upstream;
#                            review with `git diff` and commit
#
# - Existing real files are moved to <file>.bak.<timestamp> before linking;
#   correct symlinks are left alone.
# - Third-party plugins are checked out at the commits in plugins.lock, so
#   nothing unreviewed gets sourced into the shell.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$OSTYPE" in
  darwin*) SYSTEM=darwin ;;
  *)       SYSTEM=linux-gnu ;;
esac
STAMP=$(date +%Y%m%d-%H%M%S)
DO_BREW=1 DO_VIM=1 DO_UPDATE=0
for arg in "$@"; do
  case $arg in
    --no-brew) DO_BREW=0 ;;
    --no-vim)  DO_VIM=0 ;;
    --update)  DO_UPDATE=1 ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

FAILED=()
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; FAILED+=("$*"); }

# link <source in repo> <destination>
link() {
  local src=$1 dst=$2
  if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ -L $dst ]]; then
    rm "$dst"
  elif [[ -e $dst ]]; then
    mv "$dst" "$dst.bak.$STAMP" && ok "backed up $dst -> $dst.bak.$STAMP"
  fi
  ln -s "$src" "$dst" && ok "linked $dst"
}

# pin_repo <url> <dir> <commit>: make <dir> a checkout of exactly <commit>
pin_repo() {
  local url=$1 dir=$2 sha=$3
  if [[ ! -d $dir/.git ]]; then
    [[ -e $dir ]] && mv "$dir" "$dir.bak.$STAMP"
    git init -q "$dir" && git -C "$dir" remote add origin "$url"
  fi
  git -C "$dir" remote set-url origin "$url"
  [[ "$(git -C "$dir" rev-parse -q --verify HEAD 2>/dev/null)" == "$sha" ]] && return 0
  if git -C "$dir" fetch -q --depth 1 origin "$sha" 2>/dev/null &&
     git -C "$dir" -c advice.detachedHead=false checkout -q --force "$sha"; then
    ok "${dir/#$HOME/~} @ ${sha:0:10}"
  else
    warn "could not check out $url @ $sha"
  fi
}

# bump_lock: rewrite plugins.lock with each repo's latest upstream commit
bump_lock() {
  local lock=$DOTFILES/plugins.lock tmp kind name url sha new
  tmp=$(mktemp)
  while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*(#|$) ]]; then echo "$line" >> "$tmp"; continue; fi
    read -r kind name url sha <<<"$line"
    new=$(git ls-remote "$url" HEAD 2>/dev/null | cut -f1)
    if [[ -z $new ]]; then
      warn "could not reach $url"; new=$sha
    elif [[ $new != "$sha" ]]; then
      ok "$name: ${url%.git}/compare/${sha:0:10}...${new:0:10}"
    fi
    printf '%-7s %-24s %-53s %s\n' "$kind" "$name" "$url" "$new" >> "$tmp"
  done < "$lock"
  mv "$tmp" "$lock"
}

# fetch <url> <file>: download, only replacing the file on success
fetch() {
  local url=$1 dst=$2 tmp
  tmp=$(mktemp)
  if curl -fsSL "$url" -o "$tmp"; then
    mkdir -p "$(dirname "$dst")"; mv "$tmp" "$dst" && ok "fetched ${dst/#$HOME/~}"
  else
    rm -f "$tmp"; warn "could not download $url"
  fi
}

# ---------------------------------------------------------------------------
if (( DO_BREW )); then
  if [[ $SYSTEM == darwin ]]; then
    step "Homebrew packages (Brewfile)"
    if ! command -v brew >/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    brew bundle --file="$DOTFILES/Brewfile" && ok "brew bundle" || warn "brew bundle had failures"
  elif command -v apt-get >/dev/null; then
    step "apt packages"
    sudo apt-get install -y zsh git curl tmux vim fzf ripgrep fd-find bat zoxide jq \
      && ok "apt" || warn "apt install had failures"
    # Debian names: fdfind / batcat
    mkdir -p ~/.local/bin
    command -v fd  >/dev/null || { command -v fdfind >/dev/null && ln -sf "$(command -v fdfind)" ~/.local/bin/fd; }
    command -v bat >/dev/null || { command -v batcat >/dev/null && ln -sf "$(command -v batcat)" ~/.local/bin/bat; }
  fi
fi

# ---------------------------------------------------------------------------
step "Symlinks"
link "$DOTFILES/zshrc"                      ~/.zshrc
link "$DOTFILES/zshrc.fzf"                  ~/.zshrc.fzf
link "$DOTFILES/$SYSTEM/zshrc.system"       ~/.zshrc.system
link "$DOTFILES/tmux.conf"                  ~/.tmux.conf
link "$DOTFILES/$SYSTEM/tmux.system.conf"   ~/.tmux.system.conf
link "$DOTFILES/vimrc"                      ~/.vimrc
link "$DOTFILES/vimplug"                    ~/.vimplug
link "$DOTFILES/template.html"              ~/.template.html
link "$DOTFILES/agignore"                   ~/.agignore
if [[ $SYSTEM == darwin ]]; then
  cursor_dir=~/Library/Application\ Support/Cursor/User
  link "$DOTFILES/cursor/settings.json"    "$cursor_dir/settings.json"
  link "$DOTFILES/cursor/keybindings.json" "$cursor_dir/keybindings.json"
  # old VS Code setup pointed at a now-deleted repo file
  code_settings=~/Library/Application\ Support/Code/User/settings.json
  [[ -L $code_settings && "$(readlink "$code_settings")" == "$DOTFILES/"* ]] && rm "$code_settings" && ok "removed stale VS Code settings link"
fi
# links to files that have since been deleted from the repo
for l in ~/.* ~/.config/*/* ~/.local/bin/*; do
  [[ -L $l && ! -e $l && "$(readlink "$l")" == "$DOTFILES/"* ]] && rm "$l" && ok "removed stale link ${l/#$HOME/~}"
done

step "Local override files"
for f in ~/.zshrc.local ~/.tmux.local.conf ~/.vimrc.local; do
  [[ -e $f ]] || { touch "$f" && ok "created $f"; }
done

# ---------------------------------------------------------------------------
step "Git config"
# ~/.gitconfig stays machine-specific (credential helpers etc.) and includes
# the shared repo config, so edits to $DOTFILES/gitconfig apply immediately.
touch ~/.gitconfig
if git config --global --get-all include.path 2>/dev/null |
     sed "s|^~|$HOME|" | grep -qx "$DOTFILES/gitconfig"; then
  ok "~/.gitconfig already includes $DOTFILES/gitconfig"
else
  git config --global --add include.path "$DOTFILES/gitconfig" && ok "added include to ~/.gitconfig"
fi

# ---------------------------------------------------------------------------
step "Pinned plugins (plugins.lock)"
if (( DO_UPDATE )); then
  bump_lock
  # vendored single files: refresh, then review with `git diff`
  vendor() {  # vendor <raw url> <repo file> <header lines to keep>
    local tmp; tmp=$(mktemp)
    if curl -fsSL "$1" -o "$tmp"; then
      { head -n "$3" "$DOTFILES/$2"; cat "$tmp"; } > "$tmp.new" && mv "$tmp.new" "$DOTFILES/$2"
      ok "refreshed $2 (update the commit in its header if it changed)"
    else
      warn "could not download $1"
    fi
    rm -f "$tmp"
  }
  vendor https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases zsh/kubectl_aliases.zsh 2
  vendor https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.ansi-dark dircolors.ansi-dark 2
fi
ZSH_PLUGIN_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins
while read -r kind name url sha; do
  [[ -z $kind || $kind == \#* ]] && continue
  case $kind in
    zsh)  pin_repo "$url" "$ZSH_PLUGIN_DIR/$name" "$sha" ;;
    tmux) pin_repo "$url" "$HOME/.tmux/plugins/$name" "$sha" ;;
    *)    warn "unknown kind '$kind' in plugins.lock" ;;
  esac
done < "$DOTFILES/plugins.lock"
ok "plugins match plugins.lock"
link "$DOTFILES/dircolors.ansi-dark" ~/.dircolors

# one-time: carry z.sh history over to zoxide
if command -v zoxide >/dev/null && [[ -s ~/.z ]] && [[ -z "$(zoxide query -l 2>/dev/null | head -1)" ]]; then
  zoxide import --from=z ~/.z && ok "imported ~/.z into zoxide"
fi

# init scripts are cached by zshrc's cached_eval; clear so they regenerate
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/eval-*.zsh

# ---------------------------------------------------------------------------
if (( DO_VIM )); then
  step "vim plugins"
  [[ -f ~/.vim/autoload/plug.vim ]] ||
    fetch https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim ~/.vim/autoload/plug.vim
  # not -Es: vim-plug's UI raises harmless E31 errors in Ex mode
  if (( DO_UPDATE )); then
    vim -N -u ~/.vimrc +'PlugClean!' +'PlugUpdate --sync' +"PlugSnapshot! $DOTFILES/vimplug.lock" +'qa!' </dev/null >/dev/null 2>&1
    ok "PlugUpdate; new commits written to vimplug.lock"
  else
    vim -N -u ~/.vimrc +'PlugClean!' +'PlugInstall --sync' +'qa!' </dev/null >/dev/null 2>&1
    # check out the commits recorded in vimplug.lock (vim-plug's own restore is async)
    sed -nE "s/.*g:plugs\['([^']+)'\]\.commit = '([0-9a-f]+)'.*/\1 \2/p" "$DOTFILES/vimplug.lock" |
    while read -r name sha; do
      dir=~/.vim/plugged/$name
      [[ -d $dir/.git ]] || { warn "vim plugin $name missing"; continue; }
      pin_repo "$(git -C "$dir" remote get-url origin)" "$dir" "$sha"
    done
    ok "vim plugins match vimplug.lock"
  fi
fi

# ---------------------------------------------------------------------------
if [[ $SYSTEM == darwin ]]; then
  step "iTerm2"
  "$DOTFILES/darwin/iterm/install.sh" && ok "iTerm profile" || warn "iTerm profile"

  if command -v cursor >/dev/null; then
    step "Cursor extensions"
    "$DOTFILES/cursor/extensions.sh" install && ok "extensions in sync" || warn "cursor extensions"
  fi
fi

# ---------------------------------------------------------------------------
step "Done"
for old in ~/.oh-my-zsh ~/.kube-ps1 ~/.dircolors-solarized ~/.tmux/plugins/tpm ~/.tmux/plugins/tmux-colors-solarized ~/.kubectl_aliases ~/.z.sh; do
  [[ -e $old ]] && echo "  note: ${old/#$HOME/~} is no longer used; delete when happy: rm -rf ${old/#$HOME/~}"
done
[[ -d ~/.fzf ]] && command -v brew >/dev/null && brew list fzf >/dev/null 2>&1 &&
  echo "  note: ~/.fzf (git install) is superseded by brew's fzf; remove with: rm -rf ~/.fzf ~/.fzf.zsh ~/.fzf.bash"
if (( ${#FAILED[@]} )); then
  printf '\n\033[33m%d step(s) had problems:\033[0m\n' "${#FAILED[@]}"; printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
echo "  open a new shell (or: exec zsh)"
