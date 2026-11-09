# Installed by deploy.sh via `brew bundle` (installs missing, upgrades outdated).
# Machine/work-specific packages belong in `brew bundle dump`, not here.

# shell + fzf toolchain used by zshrc / zshrc.fzf
brew "fzf"
brew "ripgrep"
brew "fd"
brew "bat"
brew "zoxide"
brew "jq"
brew "yq"
brew "git-delta"     # git pager / add -p highlighting (gitconfig falls back to less without it)
brew "coreutils"     # GNU ls/dircolors (darwin/zshrc.system puts gnubin first)
brew "tmux"
brew "vim"
brew "wget"
brew "watch"

# k8s pickers (fkx, fkl, fhh...) and prompt context
brew "kubectx"
brew "helm"

# Terminal. Skipped when already installed outside brew, since `brew` refuses
# to overwrite an existing app/font.
cask "iterm2" unless File.exist?("/Applications/iTerm.app")
cask "font-meslo-for-powerline" unless File.exist?(File.expand_path("~/Library/Fonts/Meslo LG S DZ Regular for Powerline.ttf"))
