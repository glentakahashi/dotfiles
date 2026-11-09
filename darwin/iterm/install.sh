#!/usr/bin/env bash
# Install the iTerm2 "Dotfiles" profile (Solarized Dark, Meslo LG S DZ for
# Powerline 10pt, Option keys send Esc+ so alt-c/alt-r/alt-t work in zsh)
# as a Dynamic Profile and make it the default. Idempotent.
#
# To update the repo copy after tweaking the profile in iTerm's settings UI:
#   iTerm > Settings > Profiles > Dotfiles > Other Actions > Save Profile as JSON
#   and save over darwin/iterm/Dotfiles.json (keep the "Profiles" wrapper).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/Dotfiles.json"
dst_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
guid=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["Profiles"][0]["Guid"])' "$src")

mkdir -p "$dst_dir"
# copied rather than symlinked: iTerm only reliably watches real files here
if ! cmp -s "$src" "$dst_dir/Dotfiles.json"; then
  cp "$src" "$dst_dir/Dotfiles.json"
  echo "  installed Dotfiles.json dynamic profile"
fi

if [[ "$(defaults read com.googlecode.iterm2 'Default Bookmark Guid' 2>/dev/null)" != "$guid" ]]; then
  defaults write com.googlecode.iterm2 'Default Bookmark Guid' -string "$guid"
  echo "  set Dotfiles as the default iTerm profile (applies to new windows / after restart)"
fi
