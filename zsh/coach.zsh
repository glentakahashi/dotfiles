# coach: look at recent ~/.zsh_history and suggest shortcuts.
#
#   coach              full report for the last 30 days
#   coach -d 90        look further back
#   coach --claude     also ask `claude -p` for ideas (sends only the counts below)
#
# Shown automatically: a 3-4 line digest above the prompt, at most once every
# $COACH_INTERVAL_DAYS days (default 7), in the first interactive shell after
# that. It's computed in the background, so it never slows shell startup.
# COACH_INTERVAL_DAYS=0 in ~/.zshrc.local turns the automatic digest off.

: ${COACH_INTERVAL_DAYS:=7}
zmodload zsh/datetime
_coach_dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh

# things worth knowing about; shown when the history says you don't use them
# (pattern::tip). Pattern is an awk regex matched against each command.
_coach_tips=(
  '^fco( |$)::fco: fuzzy-pick a branch to check out (most recent first)'
  '^gfv( |$)::gfv [path]: fuzzy search every line in the repo, open vim at that line'
  '^frg( |$)::frg: live ripgrep (re-runs as you type), enter opens vim on the match'
  '^fga( |$)::fga: pick changed files to stage (with diff preview)'
  '^fstash( |$)::fstash: browse stashes with a diff preview; enter applies'
  '^fkl( |$)::fkl: pick a pod and tail its logs'
  '^fkx( |$)::fkx: pick a pod and exec a shell in it'
  '^fport( |$)::fport: see what is listening on which port, kill it'
  '^(j|zi)( |$)::j: fuzzy-jump to a directory you visit often (zoxide)'
  '^z ::z <part of a path>: jump to the best-matching directory you have visited'
  '^galias::galias: list the git aliases (gst, gco, gcb, grbi, gpf...)'
  '^(gpf|git push --force-with-lease)::gpf: git push --force-with-lease (safe force push)'
  '^(grbi|git rebase -i)::grbi <ref>: interactive rebase'
  '^(gsta|git stash push)::gsta / gstp: git stash push / pop'
  '^k9s::k9s: full-screen cluster UI (pods, logs, exec) instead of kubectl loops'
  '^stern ::stern <name>: tail logs from every pod matching a name at once'
  '^fzf-help::ctrl-g ctrl-b / ctrl-h / ctrl-f: insert a branch / commit / changed file at the cursor'
  '^fzf-help::alt-c: fuzzy cd into a subdirectory; alt-u: cd to a parent'
  '^fzf-help::ctrl-r then ctrl-y: copy a history entry to the clipboard instead of running it'
)

# coach [-d days] [--claude] [--digest]
coach() {
  local days=30 use_claude= digest= hist=${HISTFILE:-$HOME/.zsh_history}
  while (( $# )); do
    case $1 in
      -d) days=$2; shift ;;
      --claude) use_claude=1 ;;
      --digest) digest=1 ;;
      -h|--help) sed -n '3,6p' $DOTFILES/zsh/coach.zsh | sed 's/^# //'; return ;;
    esac
    shift
  done
  [[ -r $hist ]] || { print -u2 "coach: no history at $hist"; return 1 }

  # aliases as "name<TAB>expansion", only where the alias saves >= 4 characters
  local k tmp=$(mktemp -d)
  for k in ${(k)aliases}; do
    (( ${#aliases[$k]} - ${#k} >= 4 )) && print -r -- "$k"$'\t'"${aliases[$k]}"
  done >| $tmp/aliases
  print -rl -- $_coach_tips >| $tmp/tips

  LC_ALL=C awk -v since=$(( EPOCHSECONDS - days * 86400 )) -v digest=$digest -v days=$days \
      -v tmp=$tmp -F'\t' '
    BEGIN {
      # index aliases by the first word of their expansion
      while ((getline l < (tmp "/aliases")) > 0) {
        split(l, a, "\t"); exp_[a[1]] = a[2]; split(a[2], fw, " ")
        byword[fw[1]] = byword[fw[1]] a[1] "\034"
      }
      nt = 0; while ((getline l < (tmp "/tips")) > 0) { nt++; tpat[nt] = substr(l, 1, index(l, "::") - 1); ttxt[nt] = substr(l, index(l, "::") + 2) }
    }
    # extended history: ": <start>:<elapsed>;<command>"
    /^: [0-9]+:[0-9]+;/ {
      ts = substr($0, 3) + 0
      if (ts < since) next
      cmd = substr($0, index($0, ";") + 1)
      gsub(/[ \t]+/, " ", cmd); sub(/ $/, "", cmd)
      if (cmd == "") next
      total++
      for (i = 1; i <= nt; i++) if (cmd ~ tpat[i]) tused[i] = 1
      # longest alias expansion that this command starts with
      best = ""; bl = 0
      split(cmd, w, " ")
      nc = split(byword[w[1]], cand, "\034")
      for (c = 1; c < nc; c++) {
        n = cand[c]; e = exp_[n]
        if ((cmd == e || index(cmd, e " ") == 1) && length(e) > bl) { best = n; bl = length(e) }
      }
      if (best != "") { missed[best]++; saved[best] += length(exp_[best]) - length(best); next }
      # repeated commands with no alias: count the first two words
      key = w[1] (w[2] != "" ? " " w[2] : "")
      if (length(key) >= 10 && w[1] !~ /^(cd|vim|vi|ls|cat|echo|less|man|open|z|j)$/) { rep[key]++; full[key] = cmd }
    }
    END {
      if (!total) { print "coach: no commands in the last " days " days"; exit }
      # sort helpers (awk has no sort: emit "count<TAB>payload" and let sort do it)
      for (n in missed) printf "A\t%d\t%s\t%s\t%d\n", missed[n], n, exp_[n], saved[n] > (tmp "/out")
      for (k in rep) if (rep[k] >= 4) printf "R\t%d\t%s\n", rep[k], k > (tmp "/out")
      for (i = 1; i <= nt; i++) if (!tused[i]) printf "T\t0\t%s\n", ttxt[i] > (tmp "/out")
      printf "N\t%d\n", total > (tmp "/out")
    }' $hist

  [[ -s $tmp/out ]] || { rm -rf $tmp; return }
  local total=$(awk -F'\t' '$1=="N"{print $2}' $tmp/out) na=8 nr=6
  [[ -n $digest ]] && na=2 nr=1
  local -a A R T
  A=("${(@f)$(awk -F'\t' '$1=="A"' $tmp/out | sort -t$'\t' -k2,2nr | head -$na)}")
  R=("${(@f)$(awk -F'\t' '$1=="R"' $tmp/out | sort -t$'\t' -k2,2nr | head -$nr)}")
  T=("${(@f)$(awk -F'\t' '$1=="T"{print $3}' $tmp/out)}")
  local tip=${T[RANDOM % ${#T} + 1]} f
  rm -rf $tmp

  if [[ -n $digest ]]; then
    print -P "%F{cyan}coach%f (weekly; run %Bcoach%b for more):"
  else
    print -P "%BLast $days days%b: $total commands\n"
  fi
  if [[ -n ${A[1]} ]]; then
    [[ -z $digest ]] && print -P "%BAliases you already have%b (typed the long way):"
    for f in $A; do
      local -a c=("${(@ps:\t:)f}")
      printf "  %-8s instead of %-34s %3dx\n" "$c[3]" "${c[4][1,34]}" "$c[2]"
    done
  fi
  if [[ -n ${R[1]} ]]; then
    [[ -z $digest ]] && print -P "\n%BRepeated, no alias yet%b (add one to ~/.zshrc.local or zshrc):"
    for f in $R; do
      local -a c=("${(@ps:\t:)f}")
      printf "  %-43s %3dx\n" "${c[3][1,43]}" "$c[2]"
    done
  fi
  if [[ -n $tip ]]; then
    [[ -z $digest ]] && print -P "\n%BSomething you haven't used%b:"
    print "  tip: $tip"
  fi

  if [[ -n $use_claude ]] && (( $+commands[claude] )); then
    print -P "\n%BClaude's suggestions%b:"
    { print "Top commands from my zsh history (last $days days) with counts, and aliases I have but don't use."
      print "Suggest up to 5 concrete zsh aliases/functions or tools that would save me the most typing. Be brief; one line each."
      print
      awk '{print $1, $2}' <(LC_ALL=C sed -E -n 's/^: [0-9]+:[0-9]+;//p' $hist | tail -3000) | sort | uniq -c | sort -rn | head -40
      print; print "Aliases I have but typed the long way (count, alias, expansion):"
      for f in $A; do print -r -- "${${(@ps:\t:)f}[2,4]}"; done
    } | claude -p 2>/dev/null
  fi
}

# weekly digest: compute in the background at startup, print before a prompt
_coach_precmd() {
  if [[ -s $_coach_dir/coach-digest ]]; then
    print; cat $_coach_dir/coach-digest; print
    rm -f $_coach_dir/coach-digest
  elif [[ -e $_coach_dir/coach-digest.tmp ]]; then
    return   # still computing; try again at the next prompt
  fi
  add-zsh-hook -d precmd _coach_precmd
}
if (( COACH_INTERVAL_DAYS > 0 )) && [[ -t 1 && -z $CLAUDECODE ]]; then
  zmodload zsh/datetime
  () {
    setopt local_options extended_glob
    local stamp=$_coach_dir/coach-last
    # stamp missing, or older than the interval
    [[ -n $stamp(#qN.md-$COACH_INTERVAL_DAYS) ]] && return
    mkdir -p $_coach_dir && touch $stamp
    ( coach --digest >| $_coach_dir/coach-digest.tmp 2>/dev/null &&
        mv $_coach_dir/coach-digest.tmp $_coach_dir/coach-digest ) &!
    add-zsh-hook precmd _coach_precmd
  }
fi
