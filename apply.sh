#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

BLUE=$(printf '\033[34m')
BOLD=$(printf '\033[1m')
GREEN=$(printf '\033[32m')
RED=$(printf '\033[31m')
RESET=$(printf '\033[m')
YELLOW=$(printf '\033[33m')

# Remove newline ($'\n') from the end of input
chomp() {
    printf "%s" "${1/"$'\n'"/}"
}

cmd_exists() {
    command -v "$@" &>/dev/null
}

info() {
    printf "${BLUE}%s\n${RESET}" "$(chomp "$1")"
}

warn() {
    printf "${RED}%s\n${RESET}" "$(chomp "$1")"
}

info "Installing dotfiles..."
assets_dir=$script_dir/assets
for i in $assets_dir/*; do
    if [ -f $i ]; then
        dotfile=.$(basename $i)
        rm -f $HOME/$dotfile
        ln -sf $i $HOME/$dotfile
    fi
done

mkdir -p $HOME/.vim
info "Installing dotfiles... done"

sudo -v
while true; do sudo -n true; sleep 120; kill -0 "$$" || exit; done 2>/dev/null &

if test "$(uname)" = "Darwin"; then
    info "Installing iTerm color scheme..."
    defaults write com.googlecode.iterm2 'Custom Color Presets' -dict
    defaults write com.googlecode.iterm2 'Custom Color Presets' -dict-add \
        "material design" "$(cat $script_dir/assets/iTerm2/material-design-colors.itermcolors)"
    info "Installing iTerm color scheme... done"

    info "Configuring iTerm..."
    plist_file=com.googlecode.iterm2.plist
    cp $assets_dir/iTerm2/$plist_file $HOME/Library/Preferences
    sudo tic -xe tmux-256color $assets_dir/iTerm2/tmux-256color.info
    info "Configuring iTerm.. done"

    info "Setting up Mac OS..."
    # Refer to https://macos-defaults.com/
    defaults write com.apple.appleseed.FeedbackAssistant Autogather -bool false
    defaults write com.apple.crashreporter DialogType none
    # Trackpad > Tap to click
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    # Accessibility > Mouse & Trackpad > Trackpad Potions
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    defaults write com.apple.dock no-bouncing -bool True
    # Don’t show recent applications in Dock
    defaults write com.apple.dock show-recents -bool false
    # Dock > Automatically hide and show the Dock:
    defaults write com.apple.dock autohide -bool true
    # Dock > Automatically hide and show the Dock (delay)
    defaults write com.apple.dock autohide-delay -float 0
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool false
    defaults write com.apple.finder AppleShowAllFiles -bool false
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    # Set Default Finder Location to Home Folder
    defaults write com.apple.finder NewWindowTarget -string "PfLo" && \
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
    defaults write com.apple.finder WarnOnEmptyTrash -bool false
    defaults write com.apple.imageCapture disableHotPlug -bool true
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    defaults write com.apple.softwareupdate AutomaticDownload -int 1
    defaults write com.apple.timemachine DoNotOfferNewDisksForBackup -bool true
    defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    # Don’t automatically rearrange Spaces based on most recent use
    defaults write com.apple.dock mru-spaces -bool false
    # Set the icon size of Dock items to 36 pixels
    defaults write com.apple.dock tilesize -int 50
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
    info "Setting up Mac OS... done"

    if test ! -e /Library/Developer/CommandLineTools/usr/bin/git; then
        info "Installing CommandLineTools..."
        xcode-select --install &>/dev/null
        info "Installing CommandLineTools... done"
    fi

    info "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    info "Installing homebrew... done"

    if cmd_exists autojump; then
        info "Updating homebrew..."
        brew update > /dev/null
        info "Updating homebrew... done"

        info "Upgrading dependencies..."
        brew upgrade
        info "Upgrading dependencies... done"
    else
        info "Installing dependencies..."
        test "$(uname -m)" = "arm64" && PATH="/opt/homebrew/bin":$PATH
        brew install autojump cloc cmake htop mosh \
            the_silver_searcher tldr tmux tree vim wget
        info "Installing dependencies... done"
    fi
fi # "$(uname)" = "Darwin"

if test "$(uname)" = "Linux"; then # ubuntu
    info "Installing dependencies..."
    sudo apt update &>/dev/null
    sudo apt-get upgrade -y &>/dev/null
    sudo apt install autojump build-essential cloc cmake cscope ctags curl \
        mosh python3-pip silversearcher-ag tldr tmux tree vim \
        zsh -y &> /dev/null
    info "Installing dependencies... done"
fi

if test ! "$SHELL" = $(which zsh); then
    info "Using shell zsh..."
    sudo chsh -s $(which zsh) ${USER}
    info "Using shell zsh... done"
fi

omz_dir=$HOME/.oh-my-zsh
if test ! -d ${omz_dir}; then
    info "Installing oh-my-zsh..."
    git clone -q https://github.com/ohmyzsh/ohmyzsh.git ${omz_dir}
    info "Installing oh-my-zsh... done"
else
    info "Updating oh-my-zsh..."
    git -C $omz_dir pull -q
    info "Updating oh-my-zsh... done"
fi

vim_dir=$HOME/.vim
if test ! -e $vim_dir/autoload/plug.vim; then
    info "Installing vim pulg..."
    curl -sSfLo $vim_dir/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugClean +PlugInstall +qa
    info "Installing vim pulg... done"
fi

tr_dir=$HOME/.tmux/tmux-resurrect
if test ! -d ${tr_dir}; then
    info "Installing tmux plugin..."
    git clone -q https://github.com/tmux-plugins/tmux-resurrect ${tr_dir}
    info "Installing tmux plugin... done"
fi

echo "${YELLOW}Finished.${RESET}"

test ! "$SHELL" = $(which zsh) && exec zsh -l

set +eu; source ~/.zshrc &>/dev/null; set -eu
