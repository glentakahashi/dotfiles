#!/usr/bin/env bash
# Sync Cursor extensions with cursor/extensions.list.
#   ./cursor/extensions.sh export    write installed extensions to the list
#   ./cursor/extensions.sh install   install anything in the list that's missing
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
list="$here/extensions.list"
command -v cursor >/dev/null || { echo "cursor CLI not found (Cursor > Command Palette > Install 'cursor' command)" >&2; exit 1; }
case "${1:-}" in
  export)
    cursor --list-extensions > "$list"
    echo "wrote $(wc -l < "$list" | tr -d ' ') extensions to $list" ;;
  install)
    installed=$(cursor --list-extensions)
    while read -r ext; do
      [[ -z $ext ]] && continue
      grep -qix "$ext" <<<"$installed" || cursor --install-extension "$ext"
    done < "$list" ;;
  *) sed -n '2,4p' "$0"; exit 1 ;;
esac
