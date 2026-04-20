# toguy's dotfiles

Fedora 44 + Hyprland + Quickshell setup.

## Bootstrap a new machine

```bash
git clone --bare git@github.com:toguy/dotfiles.git $HOME/.dotfiles
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dot config --local status.showUntrackedFiles no
dot checkout    # may fail if default configs exist — move them aside
./install.sh    # installs all required packages
```

## Components

- **Hyprland** — compositor, `~/.config/hypr/`
- **Quickshell** — status bar, `~/.config/quickshell/shell.qml`
- **Kitty** — terminal, `~/.config/kitty/kitty.conf`
- **Tofi** — app launcher, `~/.config/tofi/`
- **Dunst** — notifications, `~/.config/dunst/dunstrc`
- **Starship** — shell prompt, `~/.config/starship.toml`
- **Neovim** (LazyVim) — editor, `~/.config/nvim/`

## Font

Iosevka{Term} Nerd Font. Installed via https://nerdfonts.com package.

## Theme palette

See `~/.config/quickshell/shell.qml` for the canonical color definitions.

# Daily work

```
# See what changed
dot status

# Stage & commit specific file
dot add ~/.config/quickshell/shell.qml
dot commit -m "bar: swap network module for rx/tx display"

# Pull latest on a different machine after pushing
dot pull

# See history
dot log --oneline
```

