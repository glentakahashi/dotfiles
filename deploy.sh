#!/usr/bin/env bash
# Install / update everything. Idempotent: safe to re-run any time.
#
#   ./deploy.sh              everything
#   ./deploy.sh --no-brew    skip brew bundle (packages)
#   ./deploy.sh --no-vim     skip vim-plug install/update
#
# - Existing real files are moved to <file>.bak.<timestamp> before linking;
#   correct symlinks are left alone.
# - Git repos (plugins etc.) are cloned if missing, fast-forwarded otherwise.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$OSTYPE" in
  darwin*) SYSTEM=darwin ;;
  *)       SYSTEM=linux-gnu ;;
esac
STAMP=$(date +%Y%m%d-%H%M%S)
DO_BREW=1 DO_VIM=1
for arg in "$@"; do
  case $arg in
    --no-brew) DO_BREW=0 ;;
    --no-vim)  DO_VIM=0 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
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

# sync_repo <url> <dir>
sync_repo() {
  local url=$1 dir=$2
  if [[ -d $dir/.git ]]; then
    git -C "$dir" pull --ff-only -q 2>/dev/null && ok "updated ${dir/#$HOME/~}" || warn "could not update $dir"
  else
    mkdir -p "$(dirname "$dir")"
    git clone -q --depth 1 "$url" "$dir" && ok "cloned ${dir/#$HOME/~}" || warn "could not clone $url"
  fi
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
link "$DOTFILES/tmux.reset.conf"            ~/.tmux.reset.conf
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
step "Shell plugins and helpers"
PLUGINS=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins
sync_repo https://github.com/Aloxaf/fzf-tab                      "$PLUGINS/fzf-tab"
sync_repo https://github.com/zsh-users/zsh-autosuggestions       "$PLUGINS/zsh-autosuggestions"
sync_repo https://github.com/zsh-users/zsh-syntax-highlighting   "$PLUGINS/zsh-syntax-highlighting"
sync_repo https://github.com/MichaelAquilina/zsh-you-should-use  "$PLUGINS/zsh-you-should-use"
sync_repo https://github.com/jonmosco/kube-ps1                   ~/.kube-ps1
sync_repo https://github.com/seebi/dircolors-solarized           ~/.dircolors-solarized
link ~/.dircolors-solarized/dircolors.ansi-dark ~/.dircolors
fetch https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases ~/.kubectl_aliases

# one-time: carry z.sh history over to zoxide
if command -v zoxide >/dev/null && [[ -s ~/.z ]] && [[ -z "$(zoxide query -l 2>/dev/null | head -1)" ]]; then
  zoxide import --from=z ~/.z && ok "imported ~/.z into zoxide"
fi

# init scripts are cached by zshrc's cached_eval; clear so they regenerate
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/eval-*.zsh

# ---------------------------------------------------------------------------
step "tmux plugins"
sync_repo https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins >/dev/null && ok "tpm install" || warn "tpm install"
~/.tmux/plugins/tpm/bin/update_plugins all >/dev/null && ok "tpm update" || warn "tpm update"

# ---------------------------------------------------------------------------
if (( DO_VIM )); then
  step "vim plugins"
  [[ -f ~/.vim/autoload/plug.vim ]] ||
    fetch https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim ~/.vim/autoload/plug.vim
  # not -Es: vim-plug's UI raises harmless E31 errors in Ex mode
  vim -N -u ~/.vimrc +'PlugClean!' +'PlugUpdate --sync' +'qa!' </dev/null >/dev/null 2>&1
  ok "PlugUpdate"
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
[[ -d ~/.oh-my-zsh ]] && echo "  note: ~/.oh-my-zsh is no longer used; delete it when happy: rm -rf ~/.oh-my-zsh"
[[ -d ~/.fzf ]] && command -v brew >/dev/null && brew list fzf >/dev/null 2>&1 &&
  echo "  note: ~/.fzf (git install) is superseded by brew's fzf; remove with: rm -rf ~/.fzf ~/.fzf.zsh ~/.fzf.bash"
if (( ${#FAILED[@]} )); then
  printf '\n\033[33m%d step(s) had problems:\033[0m\n' "${#FAILED[@]}"; printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
echo "  open a new shell (or: exec zsh)"
