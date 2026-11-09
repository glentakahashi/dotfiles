#!/usr/bin/env bash
# Install / update everything. Idempotent: safe to re-run any time.
#
#   ./deploy.sh              everything
#   ./deploy.sh --no-brew    skip packages (brew bundle / apt / pinned binaries)
#
# macOS, Linux (Debian/Ubuntu; other distros: install packages yourself) and
# WSL get everything. Windows Git Bash gets the git, vim and ripgrep config.
#   ./deploy.sh --update     also bump pinned third-party code (plugins.lock,
#                            vendored files) to latest upstream; review with
#                            `git diff` and commit
#
# - Existing real files are moved to <file>.bak.<timestamp> before linking;
#   correct symlinks are left alone.
# - Third-party plugins are checked out at the commits in plugins.lock, so
#   nothing unreviewed gets sourced into the shell.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$OSTYPE" in
  darwin*)              SYSTEM=darwin ;;
  msys*|cygwin*|win32*) SYSTEM=windows ;;   # Git Bash
  *)                    SYSTEM=linux-gnu ;; # incl. WSL
esac
STAMP=$(date +%Y%m%d-%H%M%S)
DO_BREW=1 DO_UPDATE=0
for arg in "$@"; do
  case $arg in
    --no-brew) DO_BREW=0 ;;
    --no-vim)  ;;   # vim plugins are part of plugins.lock now; kept for old muscle memory
    --update)  DO_UPDATE=1 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

FAILED=()
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; FAILED+=("$*"); }

# Git Bash: real symlinks need Developer Mode; otherwise link() copies
[[ $SYSTEM == windows ]] && export MSYS=winsymlinks:nativestrict

# link <source in repo> <destination>
link() {
  local src=$1 dst=$2
  if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
    return 0
  fi
  # an up-to-date copy (Git Bash without symlink support)
  [[ $SYSTEM == windows && -f $dst && ! -L $dst ]] && cmp -s "$src" "$dst" && return 0
  mkdir -p "$(dirname "$dst")"
  if [[ -L $dst ]]; then
    rm "$dst"
  elif [[ -e $dst ]]; then
    mv "$dst" "$dst.bak.$STAMP" && ok "backed up $dst -> $dst.bak.$STAMP"
  fi
  if ln -s "$src" "$dst" 2>/dev/null; then
    ok "linked $dst"
  elif [[ $SYSTEM == windows ]]; then
    cp "$src" "$dst" && ok "copied $dst (no symlink support; re-run deploy after pulling)"
  else
    warn "could not link $dst"
  fi
}

# run as root directly, otherwise via sudo
as_root() { if (( EUID == 0 )); then "$@"; else sudo "$@"; fi; }

# install_binaries: pinned, sha256-checked release binaries from binaries.lock
install_binaries() {
  local platform name version plat sha url have tmp bin
  platform="$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)"
  [[ $platform == linux-arm64 ]] && platform=linux-aarch64
  mkdir -p ~/.local/bin
  while read -r name version plat sha url; do
    [[ -z $name || $name == \#* || $plat != "$platform" ]] && continue
    have=$(~/.local/bin/"$name" --version 2>/dev/null | head -1)
    [[ $have == *"$version"* ]] && { ok "$name $version"; continue; }
    tmp=$(mktemp -d)
    if ! curl -fsSL "$url" -o "$tmp/dl.tgz"; then
      warn "could not download $url"
    elif [[ "$(sha256sum "$tmp/dl.tgz" | cut -d' ' -f1)" != "$sha" ]]; then
      warn "$name $version: sha256 mismatch for $url, not installing"
    else
      tar -xzf "$tmp/dl.tgz" -C "$tmp"
      bin=$(find "$tmp" -type f -name "$name" | head -1)
      install -m 755 "$bin" ~/.local/bin/"$name" && ok "installed $name $version (sha256 verified)"
    fi
    rm -rf "$tmp"
  done < "$DOTFILES/binaries.lock"
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
      # the installer at a reviewed commit, checked by sha256 (not HEAD piped into bash)
      brew_commit=7986efac25016e41eed7e471666140c06f9d97cf
      brew_sha=5f333bbe53bc490e51e7ccb1df8779b3dd6ee73a1a7379efda216edb08ccb148
      tmp=$(mktemp)
      curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/$brew_commit/install.sh" -o "$tmp"
      if [[ "$(shasum -a 256 "$tmp" | cut -d' ' -f1)" == "$brew_sha" ]]; then
        /bin/bash "$tmp" && eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        warn "Homebrew installer sha256 mismatch; not running it"
      fi
      rm -f "$tmp"
    fi
    brew bundle --file="$DOTFILES/Brewfile" && ok "brew bundle" || warn "brew bundle had failures"
  elif [[ $SYSTEM == linux-gnu ]]; then
    if command -v apt-get >/dev/null; then
      step "apt packages"
      # fzf and delta come from binaries.lock (the packaged ones are too old / missing)
      as_root apt-get update -qq &&
      as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        zsh git curl ca-certificates tmux vim ripgrep fd-find bat zoxide jq lsof direnv \
        && ok "apt" || warn "apt install had failures"
    else
      warn "no apt: install zsh git curl tmux vim ripgrep fd bat zoxide jq yourself"
    fi
    step "Pinned binaries (binaries.lock)"
    install_binaries
    # Debian names: fdfind / batcat
    command -v fd  >/dev/null || { command -v fdfind >/dev/null && ln -sf "$(command -v fdfind)" ~/.local/bin/fd; }
    command -v bat >/dev/null || { command -v batcat >/dev/null && ln -sf "$(command -v batcat)" ~/.local/bin/bat; }
  fi
fi

# ---------------------------------------------------------------------------
step "Symlinks"
if [[ $SYSTEM != windows ]]; then
  link "$DOTFILES/zshrc"                    ~/.zshrc
  link "$DOTFILES/zshrc.fzf"                ~/.zshrc.fzf
  link "$DOTFILES/$SYSTEM/zshrc.system"     ~/.zshrc.system
  link "$DOTFILES/tmux.conf"                ~/.tmux.conf
  link "$DOTFILES/$SYSTEM/tmux.system.conf" ~/.tmux.system.conf
fi
link "$DOTFILES/bin/copy"                   ~/.local/bin/copy
link "$DOTFILES/vimrc"                      ~/.vimrc
link "$DOTFILES/vim/colors/solarized8.vim" ~/.vim/colors/solarized8.vim
link "$DOTFILES/ripgreprc"                  ~/.config/ripgrep/config
link "$DOTFILES/git/ignore"                 ~/.config/git/ignore
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
  [[ $SYSTEM == windows && $f != *vimrc* ]] && continue
  [[ -e $f ]] || { touch "$f" && ok "created $f"; }
done

# ---------------------------------------------------------------------------
step "Git config"
# ~/.gitconfig stays machine-specific (credential helpers etc.) and includes
# the shared repo config, so edits to $DOTFILES/gitconfig apply immediately.
touch ~/.gitconfig
inc=$DOTFILES/gitconfig
# Git for Windows can't read /c/... paths in config; give it C:/...
[[ $SYSTEM == windows ]] && command -v cygpath >/dev/null && inc=$(cygpath -m "$inc")
if git config --global --get-all include.path 2>/dev/null |
     sed "s|^~|$HOME|" | grep -qxF "$inc"; then
  ok "~/.gitconfig already includes $inc"
else
  git config --global --add include.path "$inc" && ok "added include to ~/.gitconfig"
fi
# gitconfig.modern: only where git understands its values (see the file)
modern=${inc%gitconfig}gitconfig.modern
git_v=$(git --version | awk '{print $3}')
need=$(sed -n 's/^# requires: git //p' "$DOTFILES/gitconfig.modern")
has_modern=$(git config --global --get-all include.path 2>/dev/null | sed "s|^~|$HOME|" | grep -cxF "$modern")
if [[ "$(printf '%s\n' "$need" "$git_v" | sort -V | head -1)" == "$need" ]]; then
  (( has_modern )) || { git config --global --add include.path "$modern" && ok "added include of gitconfig.modern"; }
else
  (( has_modern )) && git config --global --fixed-value --unset-all include.path "$modern" 2>/dev/null
  ok "git $git_v < $need: skipping gitconfig.modern (zdiff3, autocorrect=prompt)"
fi

if [[ $SYSTEM == linux-gnu ]] && command -v zsh >/dev/null &&
   [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]]; then
  step "Login shell"
  as_root chsh -s "$(command -v zsh)" "$USER" && ok "login shell is now zsh (log in again)" || warn "chsh to zsh failed"
fi

# ---------------------------------------------------------------------------
step "Pinned plugins (plugins.lock)"
if (( DO_UPDATE )); then
  bump_lock
  # vendored single files: re-download at upstream's current commit (recorded in
  # the header), then review with `git diff`
  vendor() {  # vendor <owner/repo> <path in repo> <file in this repo>
    local repo=$1 path=$2 dst=$DOTFILES/$3 sha tmp
    sha=$(git ls-remote "https://github.com/$repo" HEAD 2>/dev/null | cut -f1)
    [[ -z $sha ]] && { warn "could not reach $repo"; return; }
    grep -q "$sha" "$dst" && return 0
    tmp=$(mktemp)
    if curl -fsSL "https://raw.githubusercontent.com/$repo/$sha/$path" -o "$tmp"; then
      { printf '# Vendored from https://github.com/%s/blob/%s/%s\n' "$repo" "$sha" "$path"
        printf '# Refresh with ./deploy.sh --update and review the diff.\n'
        cat "$tmp"; } > "$dst" && ok "refreshed $3 @ ${sha:0:10}"
    else
      warn "could not download $repo/$path @ $sha"
    fi
    rm -f "$tmp"
  }
  vendor ahmetb/kubectl-aliases      .kubectl_aliases     zsh/kubectl_aliases.zsh
  vendor seebi/dircolors-solarized   dircolors.ansi-dark  dircolors.ansi-dark
fi
ZSH_PLUGIN_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins
VIM_PACK_DIR=$HOME/.vim/pack/plugins/start
vim_wanted=()
while read -r kind name url sha; do
  [[ -z $kind || $kind == \#* ]] && continue
  case $kind in
    zsh)  command -v zsh  >/dev/null && pin_repo "$url" "$ZSH_PLUGIN_DIR/$name" "$sha" ;;
    tmux) command -v tmux >/dev/null && pin_repo "$url" "$HOME/.tmux/plugins/$name" "$sha" ;;
    vim)  pin_repo "$url" "$VIM_PACK_DIR/$name" "$sha"; vim_wanted+=("$name") ;;
    *)    warn "unknown kind '$kind' in plugins.lock" ;;
  esac
done < "$DOTFILES/plugins.lock"
# vim loads everything in pack/*/start, so remove plugins dropped from the lock
for d in "$VIM_PACK_DIR"/*/; do
  [[ -d $d ]] || continue
  n=$(basename "$d")
  [[ " ${vim_wanted[*]} " == *" $n "* ]] || { rm -rf "$d" && ok "removed vim plugin $n (not in plugins.lock)"; }
done
command -v vim >/dev/null && vim -N -u NONE -es +'helptags ALL' +'qa!' </dev/null >/dev/null 2>&1
ok "plugins match plugins.lock"
link "$DOTFILES/dircolors.ansi-dark" ~/.dircolors

# one-time on older machines: carry z.sh history over to zoxide
if command -v zoxide >/dev/null && [[ -s ~/.z ]] && [[ -z "$(zoxide query -l 2>/dev/null | head -1)" ]]; then
  zoxide import --from=z ~/.z && ok "imported ~/.z into zoxide (delete ~/.z when happy)"
fi

# init scripts are cached by zshrc's cached_eval; clear so they regenerate
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/eval-*.zsh

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
for old in ~/.vim/plugged ~/.vim/autoload/plug.vim ~/.vimplug ~/.oh-my-zsh ~/.kube-ps1 ~/.dircolors-solarized ~/.tmux/plugins/tpm ~/.tmux/plugins/tmux-colors-solarized ~/.kubectl_aliases ~/.z.sh; do
  [[ -e $old ]] && echo "  note: ${old/#$HOME/~} is no longer used; delete when happy: rm -rf ${old/#$HOME/~}"
done
[[ -d ~/.fzf ]] && command -v brew >/dev/null && brew list fzf >/dev/null 2>&1 &&
  echo "  note: ~/.fzf (git install) is superseded by brew's fzf; remove with: rm -rf ~/.fzf ~/.fzf.zsh ~/.fzf.bash"
if (( ${#FAILED[@]} )); then
  printf '\n\033[33m%d step(s) had problems:\033[0m\n' "${#FAILED[@]}"; printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
echo "  open a new shell (or: exec zsh)"
