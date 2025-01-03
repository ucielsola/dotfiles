Setup
## curl -fsSL https://ucielsola.dev/setup | bash

# List of apps to install manually
## Longshot https://apps.apple.com/cn/app/longshot-screenshot-ocr/id6450262949
## Perplexity https://apps.apple.com/us/app/perplexity-ask-anything/id6714467650

# Brew
## Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## Enable brew
(
  echo
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
) >>/Users/uciel/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

### Install packages and casks with brew
echo "Updating and upgrading homebrew"
brew update
brew upgrade

### Create LaunchAgents dir
mkdir -p ~/Library/LaunchAgents

echo "Enabling autoupdate for homebrew packages (every 12 hours)..."
brew tap homebrew/autoupdate
brew autoupdate start 43200 --upgrade

echo "Fetching Apps lists for Brew"
curl -fsSL https://raw.githubusercontent.com/ucielsola/dotfiles/refs/heads/main/brew_apps -o /tmp/brew_apps
curl -fsSL https://raw.githubusercontent.com/ucielsola/dotfiles/refs/heads/main/brew_casks -o /tmp/brew_casks

echo "Installing a bunch of apps with Brew"
brew install $(</tmp/brew_apps)
brew install --cask $(</tmp/brew_casks)

# 1Password CLI
eval "$(op signin)"

echo "Setting up SSH keys..."

# Create the .ssh directory if it doesn't exist
mkdir -p ~/.ssh

# Fetch GitHub private key
op read "op://SSH/GITHUB/private key" -o ~/.ssh/id_rsa_github
chmod 600 ~/.ssh/id_rsa_github

# Fetch GitHub public key
op read "op://SSH/GITHUB/public key" -o ~/.ssh/id_rsa_github.pub

# Fetch GitLab private key
op read "op://SSH/GITLAB/private key" -o ~/.ssh/id_rsa_gitlab
chmod 600 ~/.ssh/id_rsa_gitlab

# Fetch GitLab public key
op read "op://SSH/GITLAB/public key" -o ~/.ssh/id_rsa_gitlab.pub

# Add the private keys to the SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa_github
ssh-add ~/.ssh/id_rsa_gitlab

echo "Creating known_hosts file..."

# Backup existing known_hosts (if any)
if [ -f ~/.ssh/known_hosts ]; then
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.old
fi

# Add GitHub host keys
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Add GitLab host keys
ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

echo "known_hosts file created successfully!"

echo "Creating SSH config file..."

cat > ~/.ssh/config <<EOF
# GitHub
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa_github

# GitLab
Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_rsa_gitlab
EOF

chmod 600 ~/.ssh/config

echo "SSH config file created successfully!"

# Setup the Dock
dockutil --remove all --no-restart
dockutil --add "/Applications/Arc.app" --no-restart
dockutil --add "/Applications/Visual Studio Code.app" --no-restart
dockutil --add "/Applications/Ghostty.app" --no-restart
dockutil --add "/System/Applications/System Settings.app" --no-restart
dockutil --add '~/Downloads' --view list --display folder
dockutil --add "~/.Trash" --no-restart

dockconfig() {
  printf "\nSetting up permanent dock auto-hide.\n"
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0
  defaults write com.apple.dock static-only -bool false
}

# Dock tweaks
defaults write com.apple.dock orientation -string left # Move dock to left side of screen
defaults write com.apple.dock show-recents -bool FALSE # Disable "Show recent applications in dock"
defaults write com.apple.Dock showhidden -bool TRUE    # Show hidden applications as translucent
killall Dock

# xcode command line tools
xcode-select --install

git config --global user.name "Uciel Sola"


# Avoid the creation of .DS_Store files on network volumes or USB drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Finder tweaks
defaults write NSGlobalDomain AppleShowAllExtensions -bool true            # Show all filename extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false # Disable warning when changing a file extension
defaults write com.apple.finder FXPreferredViewStyle Clmv                  # Use column view
defaults write com.apple.finder AppleShowAllFiles -bool true               # Show hidden files
defaults write com.apple.finder ShowPathbar -bool true                     # Show path bar
defaults write com.apple.finder ShowStatusBar -bool true                   # Show status bar
killall Finder

echo "Removing config programs"
brew remove dockutil