#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
assets_dir=$script_dir/assets

info() { printf '\033[34m%s\033[m\n' "$1"; }

# Symlink dotfiles
info "Installing dotfiles..."
for i in $assets_dir/*; do
    [ -f "$i" ] && ln -sf "$i" "$HOME/.$(basename "$i")"
done
mkdir -p "$HOME/.vim"
info "Installing dotfiles... done"

sudo -v
while true; do sudo -n true; sleep 120; kill -0 "$$" || exit; done 2>/dev/null &

# macOS setup
if [ "$(uname)" = "Darwin" ]; then
    info "Configuring iTerm..."
    defaults write com.googlecode.iterm2 'Custom Color Presets' -dict
    defaults write com.googlecode.iterm2 'Custom Color Presets' -dict-add \
        "material design" "$(cat "$assets_dir/iTerm2/material-design-colors.itermcolors")"
    cp "$assets_dir/iTerm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences"
    sudo tic -xe tmux-256color "$assets_dir/iTerm2/tmux-256color.info"
    info "Configuring iTerm... done"

    # Refer to https://macos-defaults.com/
    info "Setting up macOS defaults..."
    # Trackpad
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false
    # Dock
    defaults write com.apple.dock no-bouncing -bool true
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 0
    defaults write com.apple.dock mru-spaces -bool false
    defaults write com.apple.dock tilesize -int 50
    # Finder
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder NewWindowTarget -string "PfLo"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
    defaults write com.apple.finder WarnOnEmptyTrash -bool false
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    # Misc
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    info "Setting up macOS defaults... done"

    if [ ! -e /Library/Developer/CommandLineTools/usr/bin/git ]; then
        info "Installing CommandLineTools..."
        xcode-select --install &>/dev/null
        info "Installing CommandLineTools... done"
    fi

    info "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    info "Installing homebrew... done"

    info "Installing brew dependencies..."
    [ "$(uname -m)" = "arm64" ] && PATH="/opt/homebrew/bin:$PATH"
    brew install cloc cmake htop mise mosh node@20 \
        the_silver_searcher tldr tmux tree vim wget zoxide
    info "Installing brew dependencies... done"
fi

# Set zsh as default shell
if [ ! "$SHELL" = "$(which zsh)" ]; then
    info "Switching to zsh..."
    sudo chsh -s "$(which zsh)" "${USER}"
    info "Switching to zsh... done"
fi

# Install vim-plug
if [ ! -e "$HOME/.vim/autoload/plug.vim" ]; then
    info "Installing vim-plug..."
    curl -sSfLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugClean +PlugInstall +qa
    info "Installing vim-plug... done"
fi

printf '\033[33mFinished.\033[m\n'
[ ! "$SHELL" = "$(which zsh)" ] && exec zsh -l
set +eu; source ~/.zshrc &>/dev/null; set -eu
