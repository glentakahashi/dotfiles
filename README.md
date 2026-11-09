# glen's dotfiles

zsh (vi mode, agnoster-style powerline prompt, fzf everywhere), tmux, vim,
git, iTerm2 and Cursor config for macOS (with a Linux fallback).

`gitconfig` has my name/email, so pick pieces out rather than running
`deploy.sh` blindly.

## Install / update

```sh
git clone git@github.com:glentakahashi/dotfiles.git ~/projects/dotfiles
~/projects/dotfiles/deploy.sh            # --no-brew / --no-vim to skip steps
~/projects/dotfiles/deploy.sh --update   # bump pinned plugins, then review `git diff` and commit
```

`deploy.sh` is idempotent, so re-run it whenever. It:

- installs/upgrades packages from `Brewfile` (fzf, ripgrep, fd, bat, zoxide, tmux, the Meslo powerline font, iTerm2...)
- symlinks the dotfiles into `~` (real files get backed up to `*.bak.<timestamp>`)
- makes `~/.gitconfig` include `gitconfig` (machine-specific git settings stay in `~/.gitconfig`)
- checks out third-party plugins at pinned commits: zsh/tmux plugins from `plugins.lock`, vim plugins from `vimplug.lock`. Nothing unreviewed gets sourced into the shell. `--update` bumps both and prints compare links
- small third-party files are vendored instead: `zsh/kubectl_aliases.zsh` and `dircolors.ansi-dark`
- installs the iTerm2 profile (`darwin/iterm/Dotfiles.json`: Solarized Dark, Meslo LG S DZ for Powerline 10pt, Option = Esc+) and makes it the default
- links Cursor settings/keybindings and installs extensions from `cursor/extensions.list`

Machine-local, untracked overrides: `~/.zshrc.local`, `~/.tmux.local.conf`, `~/.vimrc.local`.

## Layout

| file | what |
|---|---|
| `zshrc` | loader: options, completion, vi keys, aliases, tools, plugins |
| `zsh/options.zsh` | history (500k, secrets filtered out), dirs, terminal title |
| `zsh/completion.zsh` | cached compinit + fzf-tab |
| `zsh/prompt.zsh` | agnoster-style prompt (kube ctx, AWS profile, git, vi mode) |
| `zsh/git.zsh` | git aliases (run `galias` to list them) |
| `zshrc.fzf` | fzf config + pickers (run `fzf-help`) |
| `darwin/`, `linux-gnu/` | per-OS zsh/tmux overrides |
| `Brewfile` | packages |
| `plugins.lock`, `vimplug.lock` | pinned plugin commits |
| `gitconfig.hex` | identity + fsmonitor for `~/projects/hex` (via `includeIf`) |
| `cursor/` | Cursor settings, keybindings, extensions (`cursor/extensions.sh export` after adding some) |

## Cheat sheet

- `galias`: git aliases. You'll also get a hint after typing a long command that has an alias (zsh-you-should-use).
- `fzf-help`: fzf functions. Most used: `fco` (branch), `gfv`/`frg` (grep → vim), `fga` (stage files), `fkx`/`fkl` (pod shell/logs), `fport`.
- `ctrl-g ctrl-b` / `ctrl-h` / `ctrl-f` / `ctrl-s` / `ctrl-t`: insert branch / commit / changed file / stash / tag at the cursor.
- `ctrl-r` history, `ctrl-t` files, `alt-c` cd, `alt-u` cd to a parent, `<tab>` fzf completion menu, `j` zoxide picker.
- `git` output goes through delta. `k9s` for a cluster TUI, `stern <name>` to tail logs across pods.
- `kj` leaves insert mode; `v` in normal mode edits the line in vim.

## Profiling startup

Uncomment `zmodload zsh/zprof` at the top of `zshrc` and `zprof` at the bottom,
or just `time zsh -i -c exit`.
