# Setup
### curl -fsSL https://ucielsola.dev/setup | bash

## List of apps to install manually
### Longshot https://apps.apple.com/cn/app/longshot-screenshot-ocr/id6450262949
### Perplexity https://apps.apple.com/us/app/perplexity-ask-anything/id6714467650

## Brew
### Install brew
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

### Enable brew
# (
#   echo
#   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
# ) >>/Users/uciel/.zprofile
# eval "$(/opt/homebrew/bin/brew shellenv)"

#### Install packages and casks with brew
# echo "Updating and upgrading homebrew"
# brew update
# brew upgrade

#### Create LaunchAgents dir
mkdir -p ~/Library/LaunchAgents

echo "Enabling autoupdate for homebrew packages (every 12 hours)..."
brew tap homebrew/autoupdate
brew autoupdate start 43200 --upgrade

echo "Installing a bunch of apps with Brew"
brew install $(<brew_apps)
# brew install --cask $(<brew_casks)

# # 1Password CLI
# eval "$(op signin)"

# # Setup the Dock
# dockutil --remove all --no-restart
# dockutil --add "/Applications/Arc.app" --no-restart
# dockutil --add "/Applications/Visual Studio Code.app" --no-restart
# dockutil --add "/Applications/Ghostty.app" --no-restart
# dockutil --add "/System/Applications/System Settings.app" --no-restart
# dockutil --add '~/Downloads' --view list --display folder
# dockutil --add "~/.Trash" --no-restart

# dockconfig() {
#   printf "\nSetting up permanent dock auto-hide.\n"
#   defaults write com.apple.dock autohide -bool true
#   defaults write com.apple.dock autohide-delay -float 0
#   defaults write com.apple.dock autohide-time-modifier -float 0
#   defaults write com.apple.dock static-only -bool false
#   killall Dock
# }

# # xcode command line tools
# xcode-select --install