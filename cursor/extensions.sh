#!/usr/bin/env bash
# Sync Cursor extensions with cursor/extensions.list (name@version, pinned).
#   ./cursor/extensions.sh export    write installed extensions + versions to the list
#   ./cursor/extensions.sh install   install the listed version of anything missing/different
# settings.json turns off extension auto-update, so a hijacked publisher can't
# push a new version to this machine silently. Update from the Extensions view
# (it still shows available updates), then run `export` and review the diff.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
list="$here/extensions.list"
command -v cursor >/dev/null || { echo "cursor CLI not found (Cursor > Command Palette > Install 'cursor' command)" >&2; exit 1; }
case "${1:-}" in
  export)
    cursor --list-extensions --show-versions > "$list"
    echo "wrote $(wc -l < "$list" | tr -d ' ') extensions to $list" ;;
  install)
    installed=$(cursor --list-extensions --show-versions)
    while read -r ext; do
      [[ -z $ext ]] && continue
      grep -qix "$ext" <<<"$installed" || cursor --install-extension "$ext" --force
    done < "$list" ;;
  *) sed -n '2,7p' "$0"; exit 1 ;;
esac
