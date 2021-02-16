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

warn "May need to setup proxy to download dependencies."

info "Installing dotfiles..."
for i in $script_dir/assets/*; do
    test -f $i && ln -sf $i $HOME/.$(basename $i)
done
info "Installing dotfiles... done"

# Use existence of autojump to determine whether this is the first run.
cmd_exists autojump && {
    getopts ":f" option || true
    if [[ ! "${option}" = "f" ]]; then
        info "This is not the first time this script is run. Pass \"-f\" to run it again."
        exit 0
    fi
}

sudo -v
while true; do sudo -n true; sleep 120; kill -0 "$$" || exit; done 2>/dev/null &

if test "$(uname)" = "Darwin"; then
    info "Installing iTerm color scheme..."
    defaults write com.googlecode.iterm2 'Custom Color Presets' -dict
    defaults write com.googlecode.iterm2 'Custom Color Presets' -dict-add \
        "material design" "$(cat $script_dir/assets/material-design-colors.itermcolors)"
    info "Installing iTerm color scheme... done"

    info "Setting up macos..."
    # Refer to https://github.com/herrbischoff/awesome-macos-command-line
    defaults write com.apple.appleseed.FeedbackAssistant Autogather -bool false
    defaults write com.apple.crashreporter DialogType none
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    defaults write com.apple.dock no-bouncing -bool True
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write com.apple.finder AppleShowAllFiles -bool false
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    #Set Default Finder Location to Home Folder
    defaults write com.apple.finder NewWindowTarget -string "PfLo" && \
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
    defaults write com.apple.finder QuitMenuItem -bool true
    defaults write com.apple.finder WarnOnEmptyTrash -bool false
    defaults write com.apple.imageCapture disableHotPlug -bool true
    defaults write com.apple.launchservices LSQuarantine -bool false
    defaults write com.apple.screencapture location -string "${HOME}/Downloads"
    defaults write com.apple.softwareupdate AutomaticDownload -int 1
    defaults write com.apple.timemachine DoNotOfferNewDisksForBackup -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    # Increase sound quality for Bluetooth headphones/headsets
    defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 50
    # 0: Disable hibernation (speeds up entering sleep mode)
    sudo pmset -a hibernatemode 0
    test -e /private/var/vm/sleepimage && sudo rm /private/var/vm/sleepimage
    # sudden motion sensor
    sudo pmset -a sms 0
    info "Setting up macos... done"

    if test ! -e /Library/Developer/CommandLineTools/usr/bin/git; then
        info "Installing CommandLineTools..."
        xcode-select --install &>/dev/null
        info "Installing CommandLineTools... done"
    fi

    info "Installing tmux-256color..."
    sudo tic -xe tmux-256color ${script_dir}/assets/tmux-256color.info
    info "Installing tmux-256color... done"

    info "Installing homebrew..."
    if [ "$(uname -m)" = "arm64" ]; then
        brew_prefix="/opt/homebrew"
        alias brew=$brew_prefix/bin/brew
        sudo mkdir -p $brew_prefix
        sudo chown "$USER" $brew_prefix
        test ! -d "$brew_prefix/bin" && \
            git clone https://github.com/Homebrew/brew.git $brew_prefix
    else
        brew_prefix="/usr/local"
        test ! -d "$brew_prefix/Homebrew/bin" && {
            /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        }
    fi
    info "Installing homebrew... done"

    if cmd_exists autojump; then
        info "Updating homebrew..."
        brew update
        info "Updating homebrew... done"

        info "Upgrading dependencies..."
        brew upgrade
        info "Upgrading dependencies... done"
    else
        info "Installing dependencies..."
        brew install autojump clang-format cloc cmake cpplint golang htop llvm \
                     mosh ninja opencv@3 sshuttle the_silver_searcher tldr tmux \
                     tree vim watch wget
        info "Installing dependencies... done"
    fi
fi # "$(uname)" = "Darwin"

if test "$(uname)" = "Linux"; then # ubuntu
    info "Installing dependencies using apt..."
    sudo apt update &>/dev/null
    sudo apt-get upgrade -y
    sudo apt install autojump build-essential clang-format cloc cmake golang \
                     mosh python3.8-dev silversearcher-ag tldr tmux tree vim \
                     zsh -y
    info "Installing dependencies using apt... done"
fi

if test ! "$SHELL" = $(which zsh); then
    info "Using shell zsh..."
    sudo chsh ${USER} -s $(which zsh)
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
else
    info "Updating vim pulg..."
    vim +PlugUpgrade +PlugClean +PlugUpdate! +qa
    info "Updating vim pulg... done"
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
