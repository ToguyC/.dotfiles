#!/bin/bash
# ~/install.sh — bootstrap packages + fonts on a fresh Fedora install
# Run after cloning the dotfiles repo

set -e

# ── Colors for output readability ─────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
log() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}!!${NC} $1"; }

# ── Sanity check ──────────────────────────────────────────
if [ "$(id -u)" -eq 0 ]; then
  warn "Don't run this script as root. It will sudo when it needs to."
  exit 1
fi

# ── Core system packages ──────────────────────────────────
log "Installing core packages"
sudo dnf install -y \
  hyprland hyprpaper hyprlock hypridle hyprshot hyprcursor \
  quickshell \
  kitty dunst \
  brightnessctl pavucontrol \
  NetworkManager-tui NetworkManager-wifi \
  neovim \
  zsh \
  fzf fd-find ripgrep bat eza \
  thunar \
  grim slurp wl-clipboard \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  ImageMagick \
  unzip curl wget

# ── Building Tofi ─────────────────────
log "Downloading and Building Tofi"
git clone https://github.com/philj56/tofi.git /tmp/tofi
# Runtime dependencies
sudo dnf install -y freetype-devel cairo-devel pango-devel wayland-devel libxkbcommon-devel harfbuzz
# Build-time dependencies
sudo dnf install -y meson scdoc wayland-protocols-devel
cd /tmp/tofi
meson build && ninja -C build install
cd -
rm -rf /tmp/tofi

# ── Nerd Fonts: Iosevka + IosevkaTerm ─────────────────────
install_nerd_font() {
  local font_name="$1"
  local install_dir="$HOME/.local/share/fonts/$font_name"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"

  if [ -d "$install_dir" ] && [ -n "$(ls -A "$install_dir" 2>/dev/null)" ]; then
    log "Nerd Font '$font_name' already installed, skipping"
    return 0
  fi

  log "Downloading Nerd Font: $font_name"
  mkdir -p "$install_dir"
  local tmpzip
  tmpzip=$(mktemp --suffix=.zip)
  curl -L --fail -o "$tmpzip" "$url" || {
    warn "Failed to download $font_name"
    rm -f "$tmpzip"
    return 1
  }

  log "Extracting $font_name into $install_dir"
  unzip -o -q "$tmpzip" -d "$install_dir"
  rm -f "$tmpzip"

  # Clean noise the zip sometimes contains
  rm -f "$install_dir/README.md" "$install_dir/LICENSE" \
    "$install_dir"/*.txt 2>/dev/null || true
}

install_nerd_font "Iosevka"
install_nerd_font "IosevkaTerm"

log "Rebuilding font cache"
fc-cache -fv >/dev/null

# ── Sanity-check that the expected font families are discoverable ──
log "Verifying installed fonts"
for fam in "Iosevka Nerd Font" "IosevkaTerm Nerd Font"; do
  if fc-list | grep -qi "$fam"; then
    echo "   ✓ $fam"
  else
    warn "   ✗ $fam not found by fontconfig — configs may fall back"
  fi
done

# ── Shell: zsh as default ─────────────────────────────────
if [ "$SHELL" != "$(command -v zsh)" ]; then
  log "Setting zsh as default shell (will prompt for password)"
  chsh -s "$(command -v zsh)"
else
  log "zsh is already the default shell"
fi

log "Done."
echo
echo "Next steps:"
echo "  1. Log out and log back in for shell change & font cache to take effect"
echo "  2. Start Hyprland from your display manager / TTY"
echo "  3. Enable dunst: systemctl --user start dunst.service"
