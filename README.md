# glen's dotfiles

zsh (vi mode, agnoster-style powerline prompt, fzf everywhere), tmux, vim,
git, iTerm2 and Cursor config. macOS, Debian/Ubuntu (servers, WSL), and the
git/vim parts on Windows Git Bash.

`gitconfig` has my name/email, so pick pieces out rather than running
`deploy.sh` blindly.

## Install / update

```sh
git clone https://github.com/glentakahashi/dotfiles.git ~/projects/dotfiles   # or git@ once ssh keys exist
~/projects/dotfiles/deploy.sh            # --no-brew to skip packages
~/projects/dotfiles/deploy.sh --update   # bump pinned plugins/vendored files, then review `git diff` and commit
```

`deploy.sh` is idempotent, so re-run it whenever. It:

- **macOS**: installs/upgrades `Brewfile` (fzf, ripgrep, fd, bat, zoxide, delta, tmux, the Meslo powerline font, iTerm2...), installs the iTerm2 profile (`darwin/iterm/Dotfiles.json`) as the default, links Cursor settings and installs the pinned extensions
- **Debian/Ubuntu/WSL**: `apt-get update` + installs the same tools, plus fzf and delta from `binaries.lock` (the packaged fzf is too old for the key bindings; delta isn't packaged before Debian 13), and makes zsh the login shell. Tested on Debian 12/13 and Ubuntu 22.04/24.04 (containers)
- **Git Bash**: links `vimrc`, the vim plugins, git and ripgrep config (copies them if symlinks aren't enabled; re-run after pulling)
- symlinks the dotfiles into `~` (real files get backed up to `*.bak.<timestamp>`; links to files since deleted from the repo are removed)
- makes `~/.gitconfig` include `gitconfig` (machine-specific git settings stay in `~/.gitconfig`), plus `gitconfig.modern` when git is new enough for it
- checks out third-party zsh/tmux/vim plugins at the commits in `plugins.lock`. vim plugins are plain vim packages (`~/.vim/pack/plugins/start`), no plugin manager

Machine-local, untracked overrides: `~/.zshrc.local`, `~/.tmux.local.conf`, `~/.vimrc.local`.

## Third-party code

Nothing unreviewed gets downloaded and run:

| what | how it's pinned | to update |
|---|---|---|
| zsh/tmux/vim plugins | git commit in `plugins.lock`, canonical repo URLs (no GitHub redirects someone could re-register) | `deploy.sh --update`, review the printed compare links + `git diff plugins.lock` |
| `zsh/kubectl_aliases.zsh`, `dircolors.ansi-dark` | vendored; header records the upstream commit | `deploy.sh --update`, review `git diff` |
| `vim/colors/solarized8.vim` | vendored (upstream archived) | n/a |
| fzf, delta on Linux | version + sha256 in `binaries.lock`; a mismatch is refused | edit the version and sha256 |
| Homebrew installer | commit + sha256 in `deploy.sh` | only used on a fresh Mac |
| Homebrew / apt packages | the package managers verify their own signatures/checksums | `brew upgrade`, `apt upgrade` |
| Cursor extensions | `name@version` in `cursor/extensions.list`; auto-update is off (updates still show) | update in Cursor, then `cursor/extensions.sh export` and review |

## Layout

| file | what |
|---|---|
| `zshrc` | loader: options, completion, vi keys, aliases, tools, plugins |
| `zsh/options.zsh` | history (500k, secrets filtered out), dirs, terminal title |
| `zsh/completion.zsh` | cached compinit + fzf-tab |
| `zsh/prompt.zsh` | agnoster-style prompt (kube ctx, AWS profile, git, vi mode) |
| `zsh/git.zsh` | git aliases (run `galias` to list them) |
| `zsh/coach.zsh` | `coach`: shortcut suggestions from your history |
| `zshrc.fzf` | fzf config + pickers (run `fzf-help`) |
| `darwin/`, `linux-gnu/` | per-OS zsh/tmux overrides (locale, PATH, colors, `open` on WSL) |
| `bin/copy` | clipboard from anywhere: pbcopy / wl-copy / xclip / clip.exe, or OSC 52 over ssh |
| `Brewfile`, `binaries.lock` | packages |
| `plugins.lock` | pinned zsh/tmux/vim plugin commits |
| `gitconfig`, `gitconfig.modern`, `gitconfig.hex` | git; settings needing git 2.35+; identity + fsmonitor for `~/projects/hex` |
| `git/ignore` | global gitignore (`~/.config/git/ignore`), also read by rg and fd |
| `ripgreprc` | rg defaults |
| `config/direnv/direnv.toml` | direnv: keep "loading"/"using devbox", hide the env-var diff |
| `cursor/` | Cursor settings, keybindings, extensions (`cursor/extensions.sh export` after adding some) |

## Cheat sheet

- `coach`: what you typed the long way in the last 30 days (`-d 90` for more, `--claude` for ideas). A short digest also shows up once a week in the first new shell (`COACH_INTERVAL_DAYS=0` turns it off).
- `galias`: git aliases. You'll also get a hint after typing a long command that has an alias (zsh-you-should-use).
- `fzf-help`: fzf functions. Most used: `fco` (branch), `gfv`/`frg` (grep → vim), `fga` (stage files), `fkx`/`fkl` (pod shell/logs), `fport`.
- `ctrl-g ctrl-b` / `ctrl-h` / `ctrl-f` / `ctrl-s` / `ctrl-t`: insert branch / commit / changed file / stash / tag at the cursor.
- `ctrl-r` history, `ctrl-t` files, `alt-c` cd, `alt-u` cd to a parent, `<tab>` fzf completion menu, `j` zoxide picker.
- `git` output goes through delta. `k9s` for a cluster TUI, `stern <name>` to tail logs across pods.
- `kj` leaves insert mode; `v` in normal mode edits the line in vim.
- vim: `]b` / `[b` next/previous buffer, `C-o` / `C-i` jump back/forward (after `gg`, `/search`, `gd`...), `,d` close buffer.

## Profiling startup

Uncomment `zmodload zsh/zprof` at the top of `zshrc` and `zprof` at the bottom,
or just `time zsh -i -c exit`.
